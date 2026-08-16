import 'package:flutter/material.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> completedSets;
  final Duration duration;
  final List<Map<String, dynamic>> exercises;
  final int calories;

  const WorkoutSummaryScreen({
    super.key,
    required this.completedSets,
    required this.duration,
    required this.exercises,
    required this.calories,
  });

  int get totalReps =>
      completedSets.fold(0, (sum, set) => sum + (set["reps"] as int));
  int get totalSetsCompleted => completedSets.length;

  String get formattedDuration {
    if (duration.inSeconds < 60) return "${duration.inSeconds}s";
    if (duration.inSeconds < 3600) {
      final m = duration.inMinutes;
      final s = duration.inSeconds % 60;
      return s > 0 ? "${m}m ${s}s" : "${m}m";
    }
    return "${duration.inHours}h ${duration.inMinutes % 60}m";
  }

  String get motivationalMessage {
    if (totalSetsCompleted >= 12)
      return "Absolutely incredible! You're a beast! 🔥";
    if (totalSetsCompleted >= 8) return "Outstanding effort! Keep it up! 💪";
    if (totalSetsCompleted >= 4) return "Great job! You crushed it! 🎯";
    return "Good start! Every rep counts! ⭐";
  }

  Color _getMuscleColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push') || lower.contains('chest'))
      return const Color(0xFFFF6B9D);
    if (lower.contains('pull') || lower.contains('back'))
      return const Color(0xFF00D9FF);
    if (lower.contains('squat') ||
        lower.contains('lunge') ||
        lower.contains('leg'))
      return const Color(0xFFFFB800);
    if (lower.contains('curl') ||
        lower.contains('tricep') ||
        lower.contains('bicep'))
      return const Color(0xFF6C5CE7);
    if (lower.contains('plank') ||
        lower.contains('crunch') ||
        lower.contains('core'))
      return const Color(0xFF9B59B6);
    if (lower.contains('run') ||
        lower.contains('burpee') ||
        lower.contains('cardio'))
      return const Color(0xFFE91E63);
    return const Color(0xFF6C5CE7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text("🎉", style: TextStyle(fontSize: 60)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Workout Complete!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  motivationalMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "⏱️",
                        formattedDuration,
                        "Duration",
                        const Color(0xFF6C5CE7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        "🔥",
                        "$calories",
                        "Calories",
                        const Color(0xFFFF6B9D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        "💪",
                        "$totalSetsCompleted",
                        "Sets",
                        const Color(0xFF00D9FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        "🔄",
                        "$totalReps",
                        "Total Reps",
                        const Color(0xFFFFB800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Exercise Breakdown",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...exercises.map((exercise) {
                  final exerciseName = exercise["name"] as String;
                  final setsForExercise =
                      completedSets
                          .where((s) => s["exercise"] == exerciseName)
                          .toList();
                  final exerciseColor = _getMuscleColor(exerciseName);
                  final exerciseReps = setsForExercise.fold(
                    0,
                    (sum, s) => sum + (s["reps"] as int),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: exerciseColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exerciseName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: exerciseColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$exerciseReps total reps",
                                style: TextStyle(
                                  color: exerciseColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        setsForExercise.isEmpty
                            ? Text(
                              "No sets recorded",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 13,
                              ),
                            )
                            : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  setsForExercise.map((s) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            exerciseColor,
                                            exerciseColor.withOpacity(0.7),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "Set ${s["set"]}: ${s["reps"]} reps",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Text(
                          "Back to Home",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String emoji,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
