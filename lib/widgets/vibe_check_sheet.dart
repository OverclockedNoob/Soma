import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/active_workout_screen.dart';
import '../core/premium_ui.dart';

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

class _VibeCheckSheetState extends State<VibeCheckSheet> {
  // ── THE RECEIPTS (concrete, factual, hard to fake) ──
  int _sleepIdx = 2;      // default: 7-8h
  int _sorenessIdx = 1;   // default: light soreness
  int _motivationIdx = 0; // default: let's go

  static const _sleepOptions = ['< 5h', '5-6h', '7-8h', '8h+'];
  static const _sorenessOptions = ['Fresh', 'Light', 'Very', 'Destroyed'];
  static const _motivationOptions = ["Let's go!", 'Normal', 'Meh', 'Not really'];

  // scoring: lower = more ready
  int get _readinessScore {
    final sleepScore = [3, 2, 0, -1][_sleepIdx];
    final sorenessScore = [0, 1, 2, 3][_sorenessIdx];
    final motivationScore = [0, 1, 2, 3][_motivationIdx];
    return sleepScore + sorenessScore + motivationScore;
  }

  String get _overallStatus {
    final s = _readinessScore;
    if (s <= 1) return "Crush It! 🔥";
    if (s <= 4) return "Normal Pace 🙂";
    return "Take It Easy 😓";
  }

  Color get _statusColor {
    if (_overallStatus.contains("Crush")) return PUI.mint;
    if (_overallStatus.contains("Easy")) return PUI.pink;
    return PUI.amber;
  }

  void _startWorkout() {
    final adjustedExercises =
        widget.originalExercises.map((ex) => Map<String, dynamic>.from(ex)).toList();

    double multiplier = 1.0;
    if (_overallStatus.contains("Easy")) multiplier = 0.8;
    if (_overallStatus.contains("Crush")) multiplier = 1.1;

    for (var ex in adjustedExercises) {
      int target = (ex['targetReps'] ?? 10) as int;
      ex['targetReps'] = (target * multiplier).round();
    }

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutScreen(customExercises: adjustedExercises),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    BoxShadow(color: _statusColor.withOpacity(0.2), blurRadius: 12)
                  ],
                ),
                child: Text(
                  _overallStatus,
                  style: PUI.text(color: _statusColor, weight: FontWeight.w800, size: 16),
                ),
              ),
              const SizedBox(height: 28),

              _buildQuestion(
                "😴 Hours of sleep last night?",
                _sleepOptions,
                _sleepIdx,
                (i) => setState(() => _sleepIdx = i),
                PUI.primary,
              ),
              const SizedBox(height: 20),

              _buildQuestion(
                "🤕 How sore are you today?",
                _sorenessOptions,
                _sorenessIdx,
                (i) => setState(() => _sorenessIdx = i),
                PUI.pink,
              ),
              const SizedBox(height: 20),

              _buildQuestion(
                "⚡ Feeling like training right now?",
                _motivationOptions,
                _motivationIdx,
                (i) => setState(() => _motivationIdx = i),
                PUI.amber,
              ),
              const SizedBox(height: 28),

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