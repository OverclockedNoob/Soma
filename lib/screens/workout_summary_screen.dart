import 'package:flutter/material.dart';
import '../core/premium_ui.dart';

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

  int get totalReps => completedSets.fold(0, (sum, set) => sum + (set["reps"] as int));
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
    if (totalSetsCompleted >= 12) return "Absolutely incredible! You're a beast! 🔥";
    if (totalSetsCompleted >= 8) return "Outstanding effort! Keep it up! 💪";
    if (totalSetsCompleted >= 4) return "Great job! You crushed it! 🎯";
    return "Good start! Every rep counts! ⭐";
  }

  // 🎨 MAPPED TO PUI PALETTE
  Color _getMuscleColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push') || lower.contains('chest')) return PUI.pink;
    if (lower.contains('pull') || lower.contains('back')) return PUI.mint;
    if (lower.contains('squat') || lower.contains('lunge') || lower.contains('leg')) return PUI.amber;
    if (lower.contains('curl') || lower.contains('tricep') || lower.contains('bicep')) return PUI.primary;
    if (lower.contains('plank') || lower.contains('crunch') || lower.contains('core')) return PUI.primaryDeep;
    if (lower.contains('run') || lower.contains('burpee') || lower.contains('cardio')) return PUI.flame;
    return PUI.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PUI.bg,
      body: PopScope(
        canPop: false, // Prevents accidental swipe-back
        child: Stack(
          children: [
            const AuroraBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // ── TROPHY ORB ────────────────────────────
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [PUI.primary, PUI.primaryDeep],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PUI.primary.withOpacity(0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text("🎉", style: TextStyle(fontSize: 56)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── HEADLINE ──────────────────────────────
                    GradientText("Workout Complete!", size: 34, weight: FontWeight.w900),
                    const SizedBox(height: 12),
                    Text(
                      motivationalMessage,
                      style: PUI.text(size: 16, color: Colors.white.withOpacity(0.6)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── STATS GRID ────────────────────────────
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard("⏱️", formattedDuration, "Duration", PUI.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryCard("🔥", "$calories", "Calories", PUI.flame)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildSummaryCard("💪", "$totalSetsCompleted", "Sets", PUI.mint)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSummaryCard("🔄", "$totalReps", "Total Reps", PUI.amber)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── REWARD BANNER ─────────────────────────
                    Glass(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: PUI.mint.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.shield, color: PUI.mint, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "+1 Recovery Coin Earned!",
                            style: PUI.text(size: 16, weight: FontWeight.w800, color: PUI.mint),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── EXERCISE BREAKDOWN ────────────────────
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SectionTitle("Exercise Breakdown"),
                    ),
                    const SizedBox(height: 16),

                    ...exercises.map((exercise) {
                      final exerciseName = exercise["name"] as String;
                      final setsForExercise =
                          completedSets.where((s) => s["exercise"] == exerciseName).toList();
                      final exerciseColor = _getMuscleColor(exerciseName);
                      final exerciseReps = setsForExercise.fold(0, (sum, s) => sum + (s["reps"] as int));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Glass(
                          radius: 20,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      exerciseName,
                                      style: PUI.text(size: 17, weight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: exerciseColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: exerciseColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      "$exerciseReps reps",
                                      style: PUI.text(size: 12, weight: FontWeight.w800, color: exerciseColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              setsForExercise.isEmpty
                                  ? Text(
                                      "No sets recorded",
                                      style: PUI.text(size: 13, color: Colors.white.withOpacity(0.3)),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: setsForExercise.map((s) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [exerciseColor.withOpacity(0.8), exerciseColor.withOpacity(0.4)],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: exerciseColor.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            "Set ${s["set"]}: ${s["reps"]} reps",
                                            style: PUI.text(size: 12, weight: FontWeight.w800),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 16),

                    // ── FINISH BUTTON ─────────────────────────
                    PrimaryButton(
                      label: "Back to Home",
                      icon: Icons.home_rounded,
                      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String emoji, String value, String label, Color color) {
    return Glass(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          GradientText(value, size: 28, colors: [Colors.white, color]),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: PUI.text(
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}