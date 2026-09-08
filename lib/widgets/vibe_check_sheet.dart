import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/active_workout_screen.dart';
import '../core/premium_ui.dart';

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
  int _sleepIdx = 2;      // default: 7-8h, seems like a reasonable "average" starting point
  int _sorenessIdx = 1;   // default: light soreness
  int _motivationIdx = 0; // default: let's go — optimistic default, most people opening this are about to work out anyway

  static const _sleepOptions = ['< 5h', '5-6h', '7-8h', '8h+'];
  static const _sorenessOptions = ['Fresh', 'Light', 'Very', 'Destroyed'];
  static const _motivationOptions = ["Let's go!", 'Normal', 'Meh', 'Not really'];

  // Lower score = more ready. Note 8h+ scores lower than 7-8h (-1 vs 0) —
  // intentional, oversleeping a bit isn't really a red flag.
  int get _readinessScore {
    final sleepScore = [3, 2, 0, -1][_sleepIdx];
    final sorenessScore = [0, 1, 2, 3][_sorenessIdx];
    final motivationScore = [0, 1, 2, 3][_motivationIdx];
    return sleepScore + sorenessScore + motivationScore;
  }

  // Score range is roughly -1 to 9. Cutoffs picked by feel, not math.
  _Readiness get _readinessLevel {
    final s = _readinessScore;
    if (s <= 1) return _Readiness.crushIt;
    if (s <= 4) return _Readiness.normalPace;
    return _Readiness.takeItEasy;
  }

  String get _statusLabel {
    switch (_readinessLevel) {
      case _Readiness.crushIt:
        return "Crush It! 🔥";
      case _Readiness.normalPace:
        return "Normal Pace 🙂";
      case _Readiness.takeItEasy:
        return "Take It Easy 😓";
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

  // Drives the rep adjustment in _startWorkout(). Pulled out as its own
  // getter so the multiplier values live next to the enum they're keyed
  // off of, instead of buried in string checks inside a method.
  double get _repMultiplier {
    switch (_readinessLevel) {
      case _Readiness.crushIt:
        return 1.1;  // feeling great — push a bit harder
      case _Readiness.normalPace:
        return 1.0;
      case _Readiness.takeItEasy:
        return 0.8;  // tired/sore — back off 20%
    }
  }

  void _startWorkout() {
    final adjustedExercises =
        widget.originalExercises.map((ex) => Map<String, dynamic>.from(ex)).toList();

    // Guard: starting a "Quick Workout" with zero exercises selected used
    // to crash ActiveWorkoutScreen (it indexes [0] on an empty list).
    // Falling back to a basic full-body trio so there's always something
    // to actually do instead of throwing a RangeError mid-flow.
    if (adjustedExercises.isEmpty) {
      adjustedExercises.addAll([
        {'name': 'Push-ups', 'muscle': 'Chest', 'difficulty': 'Beginner', 'sets': 3, 'targetReps': 10},
        {'name': 'Squats', 'muscle': 'Legs', 'difficulty': 'Beginner', 'sets': 3, 'targetReps': 12},
        {'name': 'Plank', 'muscle': 'Core', 'difficulty': 'Beginner', 'sets': 3, 'targetReps': 30},
      ]);
    }

    final multiplier = _repMultiplier;
    for (var ex in adjustedExercises) {
      final target = (ex['targetReps'] ?? 10) as int;
      ex['targetReps'] = (target * multiplier).round();
    }

    Navigator.pop(context); // close the sheet before pushing the next screen

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(customExercises: adjustedExercises),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Config for the 3 questions — was three near-identical
    // _buildQuestion(...) calls before, collapsed into a loop so adding a
    // 4th question later doesn't mean copy-pasting another block.
    final questions = [
      (
        title: "😴 Hours of sleep last night?",
        options: _sleepOptions,
        selected: _sleepIdx,
        onTap: (int i) => setState(() => _sleepIdx = i),
        accent: PUI.primary,
      ),
      (
        title: "🤕 How sore are you today?",
        options: _sorenessOptions,
        selected: _sorenessIdx,
        onTap: (int i) => setState(() => _sorenessIdx = i),
        accent: PUI.pink,
      ),
      (
        title: "⚡ Feeling like training right now?",
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
            color: PUI.surface.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              GradientText("The Vibe Check", size: 24, weight: FontWeight.w900),
              const SizedBox(height: 8),
              Text(
                "3 quick receipts before ${widget.workoutName}",
                style: PUI.text(size: 14, color: Colors.white.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: _statusColor.withOpacity(0.2), blurRadius: 12),
                  ],
                ),
                child: Text(
                  _statusLabel,
                  style: PUI.text(color: _statusColor, weight: FontWeight.w800, size: 16),
                ),
              ),
              const SizedBox(height: 28),

              for (final q in questions) ...[
                _buildQuestion(q.title, q.options, q.selected, q.onTap, q.accent),
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
                      colors: [_statusColor, _statusColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 8),
                        Text("Start Workout", style: PUI.text(size: 18, weight: FontWeight.w800)),
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
      children: [
        Text(title, style: PUI.text(size: 14, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Row(
          children: List.generate(options.length, (i) {
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
                      color: isSelected ? accent.withOpacity(0.25) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accent : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        options[i],
                        style: PUI.text(
                          size: 12,
                          weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
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