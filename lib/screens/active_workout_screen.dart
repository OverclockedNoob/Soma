import 'dart:async';
import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? customExercises;

  const ActiveWorkoutScreen({super.key, this.customExercises});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late final List<Map<String, dynamic>> exercises;
  int currentExerciseIndex = 0;

  // 📝 THE DIGITAL NOTEPAD: Tracks completed sets.
  Map<String, int> completedSets = {};

  // Stopwatch
  Timer? _stopwatchTimer;
  int elapsedSeconds = 0;
  DateTime? workoutStartTime;

  @override
  void initState() {
    super.initState();
    exercises =
        widget.customExercises ??
        [
          {"name": "Push-ups", "muscle": "Chest", "sets": 3, "targetReps": 12},
          {"name": "Squats", "muscle": "Legs", "sets": 4, "targetReps": 10},
          {"name": "Plank", "muscle": "Core", "sets": 3, "targetReps": 30},
        ];
    workoutStartTime = DateTime.now();
    _startStopwatch();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => elapsedSeconds++);
    });
  }

  String get _formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // 📝 NOTEPAD LOGIC: Toggle a set on or off
  void _toggleSet(int exerciseIdx, int setIdx, int targetReps) {
    final key = "${exerciseIdx}_${setIdx}";
    setState(() {
      if (completedSets.containsKey(key)) {
        completedSets.remove(key);
      } else {
        completedSets[key] = targetReps;
      }
    });
  }

  // 📝 NOTEPAD LOGIC: Edit reps for a specific set
  void _editSetReps(int exerciseIdx, int setIdx) {
    final key = "${exerciseIdx}_${setIdx}";
    final currentReps = completedSets[key] ?? 0;
    final controller = TextEditingController(text: currentReps.toString());

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E3F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Edit Reps",
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final newReps = int.tryParse(controller.text) ?? 0;
                  setState(() {
                    if (newReps > 0) {
                      completedSets[key] = newReps;
                    } else {
                      completedSets.remove(key);
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  bool _isSetCompleted(int exerciseIdx, int setIdx) {
    return completedSets.containsKey("${exerciseIdx}_${setIdx}");
  }

  int _getSetReps(int exerciseIdx, int setIdx) {
    return completedSets["${exerciseIdx}_${setIdx}"] ?? 0;
  }

  void _nextExercise() {
    if (currentExerciseIndex < exercises.length - 1) {
      setState(() => currentExerciseIndex++);
    } else {
      _finishWorkout();
    }
  }

  void _finishWorkout() {
    _stopwatchTimer?.cancel();
    final duration = DateTime.now().difference(workoutStartTime!);
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final List<Map<String, dynamic>> finalCompletedSets = [];
    int totalReps = 0;

    completedSets.forEach((key, reps) {
      final parts = key.split('_');
      final exIdx = int.parse(parts[0]);
      final setIdx = int.parse(parts[1]);

      finalCompletedSets.add({
        "exercise": exercises[exIdx]["name"],
        "set": setIdx + 1,
        "reps": reps,
      });
      totalReps += reps;
    });

    final estimatedCalories =
        (duration.inMinutes * 6) + (finalCompletedSets.length * 3);

    WorkoutStorage.saveWorkout({
      "date": dateStr,
      "durationMinutes": duration.inMinutes,
      "calories": estimatedCalories,
      "totalSets": finalCompletedSets.length,
      "totalReps": totalReps,
      "exercises": exercises.map((e) => e["name"].toString()).toList(),
      "sets": finalCompletedSets,
    });

    // 🛡️ REWARD ENGINE: Give them 1 Recovery Coin for finishing a workout!
    SettingsStorage.addRecoveryCoins(1);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => WorkoutSummaryScreen(
              completedSets: finalCompletedSets,
              duration: duration,
              exercises: exercises,
              calories: estimatedCalories,
            ),
      ),
    );
  }

  Color _getMuscleColor(String? muscle) {
    switch (muscle) {
      case 'Chest':
        return const Color(0xFFFF6B9D);
      case 'Back':
        return const Color(0xFF00D9FF);
      case 'Legs':
        return const Color(0xFFFFB800);
      case 'Arms':
        return const Color(0xFF6C5CE7);
      case 'Core':
        return const Color(0xFF9B59B6);
      case 'Cardio':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  // 🔄 GYM TETRIS: Show equipment selection
  void _showPivotDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
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
              const Text(
                "Gym Tetris 🔄",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Machine taken? Swap to what you have:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              _buildEquipmentButton(
                "Dumbbells",
                Icons.circle,
                const Color(0xFFFF6B9D),
              ),
              const SizedBox(height: 12),
              _buildEquipmentButton(
                "Machine / Cable",
                Icons.smart_toy,
                const Color(0xFF00D9FF),
              ),
              const SizedBox(height: 12),
              _buildEquipmentButton(
                "Bodyweight Only",
                Icons.accessibility_new,
                const Color(0xFFFFB800),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEquipmentButton(String label, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          _swapExercise(label);
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }

  void _swapExercise(String equipment) {
    final currentExercise = exercises[currentExerciseIndex];
    String newExerciseName = currentExercise["name"];

    // Smart swapping logic for the default demo exercises
    if (currentExercise["name"] == "Push-ups") {
      newExerciseName =
          equipment == "Bodyweight Only"
              ? "Wall Push-ups"
              : "Dumbbell Chest Press";
    } else if (currentExercise["name"] == "Squats") {
      newExerciseName =
          equipment == "Dumbbells" ? "Goblet Squats" : "Leg Press Machine";
    } else if (currentExercise["name"] == "Plank") {
      newExerciseName = "Dead Bug";
    } else {
      newExerciseName = "$newExerciseName (Swapped)";
    }

    setState(() {
      exercises[currentExerciseIndex]["name"] = newExerciseName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white),
            const SizedBox(width: 8),
            Text("Swapped to $newExerciseName! 💪"),
          ],
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = exercises[currentExerciseIndex];
    final exerciseColor = _getMuscleColor(exercise["muscle"]);
    final totalSetsInWorkout = exercises.fold<int>(
      0,
      (sum, e) => sum + (e["sets"] as int),
    );
    final completedSetsCount = completedSets.length;
    final progress =
        totalSetsInWorkout > 0 ? completedSetsCount / totalSetsInWorkout : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed:
              () => showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        "Quit Workout?",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Your progress will be lost.",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Continue"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Quit",
                            style: TextStyle(color: Color(0xFFE91E63)),
                          ),
                        ),
                      ],
                    ),
              ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              color: Color(0xFF6C5CE7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(exerciseColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Exercise ${currentExerciseIndex + 1} of ${exercises.length}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "${(progress * 100).toInt()}% Complete",
                    style: TextStyle(
                      color: exerciseColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Exercise Header & Pivot Button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise["name"],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${exercise["sets"]} Sets × ${exercise["targetReps"]} Reps",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 🔄 GYM TETRIS PIVOT BUTTON (Wired up!)
                  GestureDetector(
                    onTap: _showPivotDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: exerciseColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: exerciseColor.withOpacity(0.5),
                        ),
                      ),
                      child: Icon(Icons.sync, color: exerciseColor, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 📝 THE DIGITAL NOTEPAD (Sets List)
              Expanded(
                child: ListView.builder(
                  itemCount: (exercise["sets"] as int) + 1,
                  itemBuilder: (context, index) {
                    // 🔄 If it's the last item, render the "Add Set" button
                    if (index == exercise["sets"]) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              exercise["sets"] = (exercise["sets"] as int) + 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: exerciseColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: exerciseColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Add Set",
                                  style: TextStyle(
                                    color: exerciseColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // 📝 Otherwise, render the normal Set Row
                    final isCompleted = _isSetCompleted(
                      currentExerciseIndex,
                      index,
                    );
                    final reps = _getSetReps(currentExerciseIndex, index);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap:
                            () => _toggleSet(
                              currentExerciseIndex,
                              index,
                              exercise["targetReps"],
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E3F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isCompleted
                                      ? exerciseColor
                                      : Colors.white.withOpacity(0.1),
                              width: isCompleted ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      isCompleted
                                          ? exerciseColor
                                          : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isCompleted
                                            ? exerciseColor
                                            : Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child:
                                    isCompleted
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                "Set ${index + 1}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap:
                                    () => _editSetReps(
                                      currentExerciseIndex,
                                      index,
                                    ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isCompleted
                                        ? "$reps reps"
                                        : "${exercise["targetReps"]} reps",
                                    style: TextStyle(
                                      color:
                                          isCompleted
                                              ? exerciseColor
                                              : Colors.white.withOpacity(0.5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Next Exercise / Finish Button
              Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [exerciseColor, exerciseColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: exerciseColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _nextExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    currentExerciseIndex < exercises.length - 1
                        ? "Next Exercise →"
                        : "Finish Workout ",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
