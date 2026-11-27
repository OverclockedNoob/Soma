import 'package:flutter/material.dart';

import '../core/premium_ui.dart';
import '../data/exercise_data.dart';
import '../models/workout_models.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final String workoutName;
  final List<Map<String, dynamic>> completedSets;
  final Duration duration;
  final List<Map<String, dynamic>> exercises;
  final int calories;
  final bool coinEarned;

  const WorkoutSummaryScreen({
    super.key,
    this.workoutName = 'Workout',
    required this.completedSets,
    required this.duration,
    required this.exercises,
    required this.calories,
    this.coinEarned = true,
  });

  List<CompletedSet> get _typedSets =>
      completedSets.map(CompletedSet.fromMap).toList();

  int get totalReps => _typedSets.fold<int>(
        0,
        (int sum, CompletedSet s) => sum + s.reps,
      );

  int get totalSetsCompleted => completedSets.length;

  String get formattedDuration {
    if (duration.inSeconds < 60) return '${duration.inSeconds}s';
    if (duration.inSeconds < 3600) {
      final m = duration.inMinutes;
      final s = duration.inSeconds % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  String get motivationalMessage {
    if (totalSetsCompleted >= 12) {
      return "Absolutely incredible! You're a beast! 🔥";
    }
    if (totalSetsCompleted >= 8) return 'Outstanding effort! Keep it up! 💪';
    if (totalSetsCompleted >= 4) return 'Great job! You crushed it! 🎯';
    return 'Good start! Every rep counts! ⭐';
  }

  List<CompletedSet> _setsForExercise(int exerciseIdx, String exerciseName) {
    final sets = _typedSets;
    final hasIndexTags = sets.any((CompletedSet s) => s.exerciseIndex != null);
    if (hasIndexTags) {
      return sets
          .where((CompletedSet s) => s.exerciseIndex == exerciseIdx)
          .toList();
    }
    return sets
        .where((CompletedSet s) => s.exercise == exerciseName)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PUI.bg,
      body: PopScope(
        canPop: false,
        child: Stack(
          children: <Widget>[
            const AuroraBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[PUI.primary, PUI.primaryDeep],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: PUI.primary.withValues(alpha: 0.5),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎉', style: TextStyle(fontSize: 56)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const GradientText(
                      'Workout Complete!',
                      size: 34,
                      weight: FontWeight.w900,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workoutName,
                      style: PUI.text(
                        size: 14,
                        weight: FontWeight.w700,
                        color: PUI.mint,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      motivationalMessage,
                      style: PUI.text(
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildSummaryCard(
                            '⏱️',
                            formattedDuration,
                            'Duration',
                            PUI.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            '🔥',
                            '$calories',
                            'Calories',
                            PUI.flame,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildSummaryCard(
                            '💪',
                            '$totalSetsCompleted',
                            'Sets',
                            PUI.mint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            '🔄',
                            '$totalReps',
                            'Total Reps',
                            PUI.amber,
                          ),
                        ),
                      ],
                    ),
                    if (coinEarned) ...<Widget>[
                      const SizedBox(height: 20),
                      Glass(
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PUI.mint.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield,
                                color: PUI.mint,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '+1 Recovery Coin Earned!',
                              style: PUI.text(
                                size: 16,
                                weight: FontWeight.w800,
                                color: PUI.mint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SectionTitle('Exercise Breakdown'),
                    ),
                    const SizedBox(height: 16),
                    ...exercises.asMap().entries.map(
                      (MapEntry<int, Map<String, dynamic>> entry) {
                        final idx = entry.key;
                        final ex = RoutineExercise.fromMap(entry.value);
                        final setsForExercise = _setsForExercise(idx, ex.name);
                        final exerciseColor =
                            ExerciseData.getMuscleColor(ex.muscle);
                        final exerciseReps = setsForExercise.fold<int>(
                          0,
                          (int sum, CompletedSet s) => sum + s.reps,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Glass(
                            radius: 20,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        ex.name,
                                        style: PUI.text(
                                          size: 17,
                                          weight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: exerciseColor.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: exerciseColor.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        '$exerciseReps reps',
                                        style: PUI.text(
                                          size: 12,
                                          weight: FontWeight.w800,
                                          color: exerciseColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                setsForExercise.isEmpty
                                    ? Text(
                                        'No sets recorded',
                                        style: PUI.text(
                                          size: 13,
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: setsForExercise.map(
                                          (CompletedSet s) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: <Color>[
                                                    exerciseColor.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                    exerciseColor.withValues(
                                                      alpha: 0.4,
                                                    ),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: <BoxShadow>[
                                                  BoxShadow(
                                                    color: exerciseColor
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                'Set ${s.setNumber}: ${s.reps} reps',
                                                style: PUI.text(
                                                  size: 12,
                                                  weight: FontWeight.w800,
                                                ),
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Back to Home',
                      icon: Icons.home_rounded,
                      onTap: () => Navigator.of(
                        context,
                      ).popUntil((Route<dynamic> route) => route.isFirst),
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

  Widget _buildSummaryCard(
    String emoji,
    String value,
    String label,
    Color color,
  ) {
    return Glass(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          GradientText(value, size: 28, colors: <Color>[Colors.white, color]),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: PUI.text(
              size: 10,
              weight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
