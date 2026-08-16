import 'package:flutter/material.dart';
import '../screens/active_workout_screen.dart';

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

  Color get _statusColor {
    if (_overallStatus.contains("Easy")) return const Color(0xFFFF6B9D); // Pink
    if (_overallStatus.contains("Crush"))
      return const Color(0xFF4CAF50); // Green
    return const Color(0xFFFFB800); // Yellow
  }

  void _startWorkout() {
    // Deep copy exercises so we don't mutate the actual database objects
    final adjustedExercises =
        widget.originalExercises
            .map((ex) => Map<String, dynamic>.from(ex))
            .toList();

    double multiplier = 1.0;
    if (_overallStatus.contains("Easy")) multiplier = 0.8; // Reduce reps by 20%
    if (_overallStatus.contains("Crush"))
      multiplier = 1.1; // Boost reps by 10% for PR attempts

    for (var ex in adjustedExercises) {
      int target = (ex['targetReps'] ?? 10) as int;
      ex['targetReps'] = (target * multiplier).round();
    }

    Navigator.pop(context); // Close sheet

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                ActiveWorkoutScreen(customExercises: adjustedExercises),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E3F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          const SizedBox(height: 20),
          const Text(
            "The Vibe Check",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "How is your body feeling for ${widget.workoutName}?",
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _statusColor),
            ),
            child: Text(
              _overallStatus,
              style: TextStyle(
                color: _statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSlider(
            "Sleep Quality 😴",
            _sleep,
            const Color(0xFF6C5CE7),
            (val) => setState(() => _sleep = val),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Stress Level 🤯",
            _stress,
            const Color(0xFFFFB800),
            (val) => setState(() => _stress = val),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Muscle Soreness 🤕",
            _soreness,
            const Color(0xFFFF6B9D),
            (val) => setState(() => _soreness = val),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: _statusColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Start Workout",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
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
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "${value.toInt()}/10",
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
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
