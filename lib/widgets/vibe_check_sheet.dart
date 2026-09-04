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
  double _sleep = 7;
  double _stress = 3;
  double _soreness = 2;

  String get _overallStatus {
    if (_sleep < 4 || _soreness > 7 || _stress > 7) return "Take It Easy 😓";
    if (_sleep >= 7 && _soreness <= 4 && _stress <= 4) return "Crush It! 🔥";
    return "Normal Pace 🙂";
  }

  // 🎨 MAPPED TO PUI PALETTE
  Color get _statusColor {
    if (_overallStatus.contains("Easy")) return PUI.pink;
    if (_overallStatus.contains("Crush")) return PUI.mint;
    return PUI.amber;
  }

  void _startWorkout() {
    // Deep copy exercises so we don't mutate the actual database objects
    final adjustedExercises =
        widget.originalExercises.map((ex) => Map<String, dynamic>.from(ex)).toList();

    double multiplier = 1.0;
    if (_overallStatus.contains("Easy")) multiplier = 0.8; // Reduce reps by 20%
    if (_overallStatus.contains("Crush")) multiplier = 1.1; // Boost reps by 10%

    for (var ex in adjustedExercises) {
      int target = (ex['targetReps'] ?? 10) as int;
      ex['targetReps'] = (target * multiplier).round();
    }

    Navigator.pop(context); // Close sheet

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
              // ── DRAG HANDLE ────────────────────────────────
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // ── HEADER ─────────────────────────────────────
              GradientText("The Vibe Check", size: 24, weight: FontWeight.w900),
              const SizedBox(height: 8),
              Text(
                "How is your body feeling for ${widget.workoutName}?",
                style: PUI.text(size: 14, color: Colors.white.withOpacity(0.6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── STATUS PILL ────────────────────────────────
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
              const SizedBox(height: 32),

              // ── SLIDERS ────────────────────────────────────
              _buildSlider("Sleep Quality 😴", _sleep, PUI.primary, (val) => setState(() => _sleep = val)),
              const SizedBox(height: 24),
              _buildSlider("Stress Level 🤯", _stress, PUI.amber, (val) => setState(() => _stress = val)),
              const SizedBox(height: 24),
              _buildSlider("Muscle Soreness 🤕", _soreness, PUI.pink, (val) => setState(() => _soreness = val)),
              const SizedBox(height: 36),

              // ── START BUTTON ───────────────────────────────
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

  Widget _buildSlider(
    String title,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: PUI.text(size: 15, weight: FontWeight.w700)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${value.toInt()}/10",
                style: PUI.text(color: color, size: 14, weight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withOpacity(0.05),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}