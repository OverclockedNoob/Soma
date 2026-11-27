import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/premium_ui.dart';
import '../screens/active_workout_screen.dart';

// Quick pre-workout check-in. Ask 3 questions, turn the answers into a
// readiness score, and use that to nudge the workout's rep targets up or
// down. Nothing scientific about the numbers below — just felt right
// during testing. Adjust freely if it feels off in practice.
class VibeCheckSheet extends StatefulWidget {
  final List<Map<String, dynamic>> originalExercises;
  final String workoutName;

  const VibeCheckSheet({
    super.key,
    required this.originalExercises,
    required this.workoutName,
  });

  @override
  State<VibeCheckSheet> createState() => _VibeCheckSheetState();
}

// Buckets the raw score into 3 tiers. Kept as an enum instead of matching
// on the display string (used to do that — turned out to be fragile since
// the display text has emoji baked in and any copy change would've quietly
// broken the rep multiplier logic below).
enum _Readiness { crushIt, normalPace, takeItEasy }

class _VibeCheckSheetState extends State<VibeCheckSheet> {
  // Defaults are deliberately "average" so that tapping Start without
  // touching anything lands on Normal Pace (score 2 -> 1.0x), not on a
  // rep bump the user never asked for.
  int _sleepIdx = 2; // 7-8h
  int _sorenessIdx = 1; // Light
  int _motivationIdx = 1; // Normal

  // Guards against a double-tap on Start popping the route twice.
  bool _starting = false;

  static const List<String> _sleepOptions = <String>[
    '< 5h',
    '5-6h',
    '7-8h',
    '8h+',
  ];
  static const List<String> _sorenessOptions = <String>[
    'Fresh',
    'Light',
    'Very',
    'Destroyed',
  ];
  static const List<String> _motivationOptions = <String>[
    "Let's go!",
    'Normal',
    'Meh',
    'Not really',
  ];

  static const int _verySoreIdx = 2;
  static const int _destroyedIdx = 3;

  static const int _defaultTargetReps = 10;
  static const int _minTargetReps = 1;
  static const int _maxTargetReps = 999;

  // Used when the sheet is opened with no exercises. Const so it can't be
  // mutated by accident; always copied before use.
  static const List<Map<String, dynamic>> _fallbackExercises =
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'Push-ups',
          'muscle': 'Chest',
          'difficulty': 'Beginner',
          'sets': 3,
          'targetReps': 10,
        },
        <String, dynamic>{
          'name': 'Squats',
          'muscle': 'Legs',
          'difficulty': 'Beginner',
          'sets': 3,
          'targetReps': 12,
        },
        <String, dynamic>{
          'name': 'Plank',
          'muscle': 'Core',
          'difficulty': 'Beginner',
          'sets': 3,
          'targetReps': 30,
        },
      ];

  // Lower score = more ready. Note 8h+ scores lower than 7-8h (-1 vs 0) —
  // intentional, oversleeping a bit isn't really a red flag.
  // Score range is exactly -1 to 9.
  int get _readinessScore {
    final sleepScore = const <int>[3, 2, 0, -1][_sleepIdx];
    final sorenessScore = const <int>[0, 1, 2, 3][_sorenessIdx];
    final motivationScore = const <int>[0, 1, 2, 3][_motivationIdx];
    return sleepScore + sorenessScore + motivationScore;
  }

  // Cutoffs picked by feel, not math. Soreness gets hard overrides so a
  // single strong red flag can't be averaged away by the other answers:
  //  - "Destroyed" always means Take It Easy.
  //  - "Very" sore can never be Crush It (e.g. very sore + 8h+ sleep +
  //    motivated would otherwise score 1).
  _Readiness get _readinessLevel {
    if (_sorenessIdx == _destroyedIdx) return _Readiness.takeItEasy;

    final s = _readinessScore;
    if (s <= 1) {
      return _sorenessIdx >= _verySoreIdx
          ? _Readiness.normalPace
          : _Readiness.crushIt;
    }
    if (s <= 4) return _Readiness.normalPace;
    return _Readiness.takeItEasy;
  }

  String get _statusLabel {
    switch (_readinessLevel) {
      case _Readiness.crushIt:
        return 'Crush It! 🔥';
      case _Readiness.normalPace:
        return 'Normal Pace 🙂';
      case _Readiness.takeItEasy:
        return 'Take It Easy 😓';
    }
  }

  Color get _statusColor {
    switch (_readinessLevel) {
      case _Readiness.crushIt:
        return PUI.mint;
      case _Readiness.normalPace:
        return PUI.amber;
      case _Readiness.takeItEasy:
        return PUI.pink;
    }
  }

  // Text/icon color for the Start button, chosen from the background's
  // luminance so it stays readable on light colors like mint/amber.
  Color get _buttonForeground {
    return ThemeData.estimateBrightnessForColor(_statusColor) ==
            Brightness.light
        ? Colors.black87
        : Colors.white;
  }

  // Drives the rep adjustment in _startWorkout(). Pulled out as its own
  // getter so the multiplier values live next to the enum they're keyed
  // off of, instead of buried in string checks inside a method.
  double get _repMultiplier {
    switch (_readinessLevel) {
      case _Readiness.crushIt:
        return 1.1; // feeling great — push a bit harder
      case _Readiness.normalPace:
        return 1.0;
      case _Readiness.takeItEasy:
        return 0.8; // tired/sore — back off 20%
    }
  }

  // Tolerant of int / double / numeric String / null.
  int _parseTargetReps(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    if (raw is String) {
      return int.tryParse(raw) ??
          double.tryParse(raw)?.round() ??
          _defaultTargetReps;
    }
    return _defaultTargetReps;
  }

  void _startWorkout() {
    if (_starting) return;
    _starting = true;

    final adjustedExercises = widget.originalExercises
        .map((Map<String, dynamic> ex) => Map<String, dynamic>.from(ex))
        .toList();

    // Guard: starting with zero exercises used to crash ActiveWorkoutScreen
    // (it indexes [0] on an empty list). The sheet tells the user when this
    // fallback will be used.
    if (adjustedExercises.isEmpty) {
      adjustedExercises.addAll(
        _fallbackExercises.map(
          (Map<String, dynamic> ex) => Map<String, dynamic>.from(ex),
        ),
      );
    }

    final multiplier = _repMultiplier;
    for (final ex in adjustedExercises) {
      final target = _parseTargetReps(ex['targetReps']);
      ex['targetReps'] = (target * multiplier)
          .round()
          .clamp(_minTargetReps, _maxTargetReps);
    }

    // Capture the navigator up front so we don't depend on this sheet's
    // context after it has been popped.
    final navigator = Navigator.of(context);
    navigator.pop(); // close the sheet before pushing the next screen
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ActiveWorkoutScreen(
            workoutName: widget.workoutName,
            customExercises: adjustedExercises,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Config for the questions — adding another one later is a single new
    // entry here.
    final questions = <({
      String title,
      List<String> options,
      int selected,
      ValueChanged<int> onTap,
      Color accent,
    })>[
      (
        title: '😴 Hours of sleep last night?',
        options: _sleepOptions,
        selected: _sleepIdx,
        onTap: (int i) => setState(() => _sleepIdx = i),
        accent: PUI.primary,
      ),
      (
        title: '🤕 How sore are you today?',
        options: _sorenessOptions,
        selected: _sorenessIdx,
        onTap: (int i) => setState(() => _sorenessIdx = i),
        accent: PUI.pink,
      ),
      (
        title: '⚡ Feeling like training right now?',
        options: _motivationOptions,
        selected: _motivationIdx,
        onTap: (int i) => setState(() => _motivationIdx = i),
        accent: PUI.amber,
      ),
    ];

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final foreground = _buttonForeground;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          // Lower opacity than before (was 0.9) so the blur is visible.
          decoration: BoxDecoration(
            color: PUI.surface.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          // Scrollable so small screens, landscape and large text scales
          // scroll instead of overflowing.
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 34 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const GradientText(
                  'The Vibe Check',
                  size: 24,
                  weight: FontWeight.w900,
                ),
                const SizedBox(height: 8),
                Text(
                  '${questions.length} quick receipts before ${widget.workoutName}',
                  style: PUI.text(
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.originalExercises.isEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    "No exercises selected — we'll start you with a quick full-body routine.",
                    style: PUI.text(
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                Semantics(
                  liveRegion: true, // announce changes to screen readers
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor.withValues(alpha: 0.5),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: _statusColor.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      _statusLabel,
                      style: PUI.text(
                        color: _statusColor,
                        weight: FontWeight.w800,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                for (final q in questions) ...<Widget>[
                  _buildQuestion(
                    q.title,
                    q.options,
                    q.selected,
                    q.onTap,
                    q.accent,
                  ),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  label: 'Start workout',
                  excludeSemantics: true,
                  onTap: _startWorkout,
                  child: Pressable(
                    onTap: _startWorkout,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            _statusColor,
                            _statusColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: _statusColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.play_arrow_rounded,
                              color: foreground,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Start Workout',
                              style: PUI.text(
                                size: 18,
                                weight: FontWeight.w800,
                                color: foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(
    String title,
    List<String> options,
    int selected,
    ValueChanged<int> onTap,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: PUI.text(size: 14, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List<Widget>.generate(options.length, (int i) {
            final isSelected = i == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: options[i],
                  excludeSemantics: true,
                  onTap: () => onTap(i),
                  child: Pressable(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        // Shrinks long labels ("Destroyed", "Not really")
                        // instead of wrapping or overflowing.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            options[i],
                            maxLines: 1,
                            style: PUI.text(
                              size: 12,
                              weight:
                                  isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
