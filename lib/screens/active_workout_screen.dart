import 'dart:async';
import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'workout_summary_screen.dart';
import '../core/event_bus.dart';

// Heads up: this screen predates (or just never got updated to use) the
// PUI design system that the rest of the app runs on — everything here
// is hardcoded hex colors instead of PUI.bg / PUI.primary / etc. They
// look close enough to match visually, but if the theme ever changes
// this screen won't follow along. Left as local constants for now
// rather than guessing at a PUI swap and risking a visual break on the
// most important screen in the app — worth revisiting properly later.
class _Chrome {
  static const bg = Color(0xFF0A0E21);
  static const card = Color(0xFF1E1E3F);
  static const accent = Color(0xFF6C5CE7);
  static const danger = Color(0xFFE91E63);
}

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? customExercises;

  const ActiveWorkoutScreen({super.key, this.customExercises});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late final List<Map<String, dynamic>> exercises;
  int currentExerciseIndex = 0;

  // key format is "exerciseIdx_setIdx" -> reps completed for that set
  Map<String, int> completedSets = {};

  Timer? _stopwatchTimer;
  int elapsedSeconds = 0;
  DateTime? workoutStartTime;

  // exercise data can come from a few different places (library, vibe
  // check adjustments, custom workouts) and isn't always typed
  // consistently — this just makes sure we always end up with an int
  // no matter what shape the incoming value is
  static int _asInt(dynamic v, int fallback) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? fallback;

  @override
  void initState() {
    super.initState();

    const defaults = [
      {"name": "Push-ups", "muscle": "Chest", "sets": 3, "targetReps": 12},
      {"name": "Squats", "muscle": "Legs", "sets": 4, "targetReps": 10},
      {"name": "Plank", "muscle": "Core", "sets": 3, "targetReps": 30},
    ];

    exercises = (widget.customExercises ?? defaults).map((e) {
      final m = Map<String, dynamic>.from(e);
      m["name"] = m["name"]?.toString() ?? "Exercise";
      m["sets"] = _asInt(m["sets"], 3);
      m["targetReps"] = _asInt(m["targetReps"], 10);
      return m;
    }).toList();

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

  void _toggleSet(int exerciseIdx, int setIdx, int targetReps) {
    final key = "${exerciseIdx}_$setIdx";
    setState(() {
      if (completedSets.containsKey(key)) {
        completedSets.remove(key);
      } else {
        completedSets[key] = targetReps;
      }
    });
  }

  void _editSetReps(int exerciseIdx, int setIdx) {
    final key = "${exerciseIdx}_$setIdx";
    final currentReps = completedSets[key] ?? 0;
    final controller = TextEditingController(text: currentReps.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Chrome.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Reps", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
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
            style: ElevatedButton.styleFrom(backgroundColor: _Chrome.accent),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _isSetCompleted(int exerciseIdx, int setIdx) {
    return completedSets.containsKey("${exerciseIdx}_$setIdx");
  }

  int _getSetReps(int exerciseIdx, int setIdx) {
    return completedSets["${exerciseIdx}_$setIdx"] ?? 0;
  }

  void _nextExercise() {
    if (currentExerciseIndex < exercises.length - 1) {
      setState(() => currentExerciseIndex++);
    } else {
      _finishWorkout();
    }
  }

  // Rough calorie estimate using the standard MET formula:
  //   calories = MET × weight(kg) × hours
  // This is not medically precise — MET values are just approximate
  // averages per exercise type (see _getMETForExercise below), and we're
  // averaging across the whole workout rather than weighting by how long
  // each exercise actually took. Good enough for a ballpark number on
  // the stats screen, not something to build a diet plan around.
  int _calculateCalories(Duration duration) {
    final weight = SettingsStorage.getWeight();
    final minutes = duration.inMinutes;

    if (minutes < 1) return 0;

    double avgMET = 0;
    for (var ex in exercises) {
      avgMET += _getMETForExercise(ex['name'] as String);
    }
    avgMET /= exercises.length;

    return (avgMET * weight * (minutes / 60)).round();
  }

  // Matching by keyword in the exercise name since we don't have a
  // proper MET value stored per exercise in the library data. Crude but
  // works reasonably well for the common cases.
  double _getMETForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('run') || lower.contains('sprint') || lower.contains('hiit')) return 9.0;
    if (lower.contains('squat') || lower.contains('deadlift') || lower.contains('clean')) return 7.0;
    if (lower.contains('push') || lower.contains('press') || lower.contains('pull')) return 6.0;
    if (lower.contains('plank') || lower.contains('crunch') || lower.contains('core')) return 3.5;
    if (lower.contains('cardio') || lower.contains('bike') || lower.contains('cycle')) return 8.0;
    return 5.0; // fallback for anything that doesn't match a keyword above
  }

  Future<void> _finishWorkout() async {
    _stopwatchTimer?.cancel();
    final duration = DateTime.now().difference(workoutStartTime!);
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

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

    final estimatedCalories = _calculateCalories(duration);

    final saved = await WorkoutStorage.saveWorkout({
      "date": dateStr,
      "durationMinutes": duration.inMinutes,
      "calories": estimatedCalories,
      "totalSets": finalCompletedSets.length,
      "totalReps": totalReps,
      "exercises": exercises.map((e) => e["name"].toString()).toList(),
      "sets": finalCompletedSets,
    });

    // Coin as a small reward for finishing — only if the save actually
    // worked, no point rewarding a workout that didn't get recorded
    if (saved) await SettingsStorage.addRecoveryCoins(1);

    // let Home/Stats know so they refresh instantly instead of showing
    // stale numbers until the user manually pulls to refresh
    WorkoutEventBus.instance.notifyWorkoutChanged();

    if (!mounted) return;

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save workout — check storage.")),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutSummaryScreen(
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
      case 'Chest': return const Color(0xFFFF6B9D);
      case 'Back': return const Color(0xFF00D9FF);
      case 'Legs': return const Color(0xFFFFB800);
      case 'Arms': return const Color(0xFF6C5CE7);
      case 'Core': return const Color(0xFF9B59B6);
      case 'Cardio': return const Color(0xFFE91E63);
      default: return _Chrome.accent;
    }
  }

  // "Gym Tetris" — lets you swap an exercise mid-workout if the equipment
  // you need is taken. Small quality-of-life thing, not trying to be a
  // real exercise substitution engine, just covers the common cases.
  void _showPivotDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _Chrome.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text("Gym Tetris 🔄", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text("Machine taken? Swap to what you have:", style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 24),
            _buildEquipmentButton("Dumbbells", Icons.circle, const Color(0xFFFF6B9D)),
            const SizedBox(height: 12),
            _buildEquipmentButton("Machine / Cable", Icons.smart_toy, const Color(0xFF00D9FF)),
            const SizedBox(height: 12),
            _buildEquipmentButton("Bodyweight Only", Icons.accessibility_new, const Color(0xFFFFB800)),
            const SizedBox(height: 24),
          ],
        ),
      ),
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
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
    );
  }

  // Hardcoded swap rules for the 3 default exercises — anything outside
  // that list just gets "(Swapped)" tacked onto its name. Fine for now
  // since this only really matters for the built-in defaults; custom
  // workouts from the library rarely hit this path.
  void _swapExercise(String equipment) {
    final currentExercise = exercises[currentExerciseIndex];
    String newExerciseName = currentExercise["name"];

    if (currentExercise["name"] == "Push-ups") {
      newExerciseName = equipment == "Bodyweight Only" ? "Wall Push-ups" : "Dumbbell Chest Press";
    } else if (currentExercise["name"] == "Squats") {
      newExerciseName = equipment == "Dumbbells" ? "Goblet Squats" : "Leg Press Machine";
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
        content: Row(children: [const Icon(Icons.sync, color: Colors.white), const SizedBox(width: 8), Text("Swapped to $newExerciseName! 💪")]),
        backgroundColor: _Chrome.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = exercises[currentExerciseIndex];
    final exerciseColor = _getMuscleColor(exercise["muscle"]);
    final totalSetsInWorkout = exercises.fold<int>(0, (sum, e) => sum + (e["sets"] as int));
    final completedSetsCount = completedSets.length;
    final progress = totalSetsInWorkout > 0 ? completedSetsCount / totalSetsInWorkout : 0.0;

    return Scaffold(
      backgroundColor: _Chrome.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: _Chrome.card,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Quit Workout?", style: TextStyle(color: Colors.white)),
              content: const Text("Your progress will be lost.", style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Continue")),
                TextButton(
                  onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                  child: const Text("Quit", style: TextStyle(color: _Chrome.danger)),
                ),
              ],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: _Chrome.accent, size: 20),
            const SizedBox(width: 8),
            Text(_formattedTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
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
                  Text("Exercise ${currentExerciseIndex + 1} of ${exercises.length}", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  Text("${(progress * 100).toInt()}% Complete", style: TextStyle(color: exerciseColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise["name"], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text("${exercise["sets"]} Sets × ${exercise["targetReps"]} Reps", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showPivotDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: exerciseColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: exerciseColor.withOpacity(0.5)),
                      ),
                      child: Icon(Icons.sync, color: exerciseColor, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.builder(
                  // +1 for the trailing "Add Set" row
                  itemCount: (exercise["sets"] as int) + 1,
                  itemBuilder: (context, index) {
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
                              border: Border.all(color: exerciseColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, color: exerciseColor, size: 24),
                                const SizedBox(width: 8),
                                Text("Add Set", style: TextStyle(color: exerciseColor, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final isCompleted = _isSetCompleted(currentExerciseIndex, index);
                    final reps = _getSetReps(currentExerciseIndex, index);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _toggleSet(currentExerciseIndex, index, exercise["targetReps"]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: _Chrome.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCompleted ? exerciseColor : Colors.white.withOpacity(0.1),
                              width: isCompleted ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: isCompleted ? exerciseColor : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isCompleted ? exerciseColor : Colors.white.withOpacity(0.3), width: 2),
                                ),
                                child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                              ),
                              const SizedBox(width: 16),
                              Text("Set ${index + 1}", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _editSetReps(currentExerciseIndex, index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    isCompleted ? "$reps reps" : "${exercise["targetReps"]} reps",
                                    style: TextStyle(color: isCompleted ? exerciseColor : Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
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

              Container(
                width: double.infinity,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [exerciseColor, exerciseColor.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: exerciseColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: ElevatedButton(
                  onPressed: _nextExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    currentExerciseIndex < exercises.length - 1 ? "Next Exercise →" : "Finish Workout",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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