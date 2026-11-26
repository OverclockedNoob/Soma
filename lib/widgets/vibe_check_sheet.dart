import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/premium_ui.dart';
import '../models/workout_models.dart';
import '../screens/active_workout_screen.dart';

enum ReadinessLevel { crushIt, normalPace, takeItEasy }

/// Pre-workout readiness check-in that adapts rep targets based on sleep,
/// soreness, and motivation before starting [ActiveWorkoutScreen].
class VibeCheckSheet extends StatefulWidget {
  final List<Map<String, dynamic>> originalExercises;
  final String workoutName;

  const VibeCheckSheet({
    super.key,
    required this.originalExercises,
    required this.workoutName,
  });

  static const List<Map<String, dynamic>> defaultQuickExercises =
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

  static int computeReadinessScore({
    required int sleepIndex,
    required int sorenessIndex,
    required int motivationIndex,
  }) {
    const sleepScores = <int>[3, 2, 0, -1];
    const sorenessScores = <int>[0, 1, 2, 3];
    const motivationScores = <int>[0, 1, 2, 3];
    return sleepScores[sleepIndex.clamp(0, 3)] +
        sorenessScores[sorenessIndex.clamp(0, 3)] +
        motivationScores[motivationIndex.clamp(0, 3)];
  }

  static ReadinessLevel readinessForScore(int score) {
    if (score <= 1) return ReadinessLevel.crushIt;
    if (score <= 4) return ReadinessLevel.normalPace;
    return ReadinessLevel.takeItEasy;
  }

  static double multiplierForReadiness(ReadinessLevel level) {
    switch (level) {
      case ReadinessLevel.crushIt:
        return 1.1;
      case ReadinessLevel.normalPace:
        return 1.0;
      case ReadinessLevel.takeItEasy:
        return 0.8;
    }
  }

  static List<Map<String, dynamic>> adjustExercises(
    List<Map<String, dynamic>> source,
    double multiplier,
  ) {
    final seed = source.isEmpty ? defaultQuickExercises : source;
    return seed.map((Map<String, dynamic> raw) {
      final exercise = RoutineExercise.fromMap(raw);
      final adjustedReps = max(1, (exercise.targetReps * multiplier).round());
      return exercise.copyWith(targetReps: adjustedReps).toMap();
    }).toList();
  }

  @override
  State<VibeCheckSheet> createState() => _VibeCheckSheetState();
}

class _VibeCheckSheetState extends State<VibeCheckSheet> {
  int _sleepIdx = 2; // 7-8h
  int _sorenessIdx = 1; // Light
  int _motivationIdx = 0; // Let's go!

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

  int get _readinessScore => VibeCheckSheet.computeReadinessScore(
        sleepIndex: _sleepIdx,
        sorenessIndex: _sorenessIdx,
        motivationIndex: _motivationIdx,
      );

  ReadinessLevel get _readinessLevel =>
      VibeCheckSheet.readinessForScore(_readinessScore);

  String get _statusLabel {
    switch (_readinessLevel) {
      case ReadinessLevel.crushIt:
        return 'Crush It! 🔥';
      case ReadinessLevel.normalPace:
        return 'Normal Pace 🙂';
      case ReadinessLevel.takeItEasy:
        return 'Take It Easy 😓';
    }
  }

  Color get _statusColor {
    switch (_readinessLevel) {
      case ReadinessLevel.crushIt:
        return PUI.mint;
      case ReadinessLevel.normalPace:
        return PUI.amber;
      case ReadinessLevel.takeItEasy:
        return PUI.pink;
    }
  }

  double get _repMultiplier =>
      VibeCheckSheet.multiplierForReadiness(_readinessLevel);

  void _startWorkout() {
    final adjustedExercises = VibeCheckSheet.adjustExercises(
      widget.originalExercises,
      _repMultiplier,
    );

    // Capture the NavigatorState before popping this sheet so we never call
    // Navigator.push on an unmounted bottom-sheet BuildContext.
    final navigator = Navigator.of(context);
    navigator.pop();
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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PUI.surface.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
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
                  '3 quick check-ins before ${widget.workoutName}',
                  style: PUI.text(
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AnimatedContainer(
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
                Pressable(
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
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start Workout',
                            style: PUI.text(size: 18, weight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
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
        Text(title, style: PUI.text(size: 14, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: List<Widget>.generate(options.length, (int i) {
            final isSelected = i == selected;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Pressable(
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                      child: Text(
                        options[i],
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
            );
          }),
        ),
      ],
    );
  }
}
