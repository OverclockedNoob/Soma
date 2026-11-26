import 'dart:async';

import 'package:flutter/material.dart';

import '../core/premium_ui.dart';
import '../data/exercise_data.dart';
import '../models/workout_models.dart';
import '../services/exercise_service.dart';
import '../services/storage_services.dart';
import '../widgets/vibe_check_sheet.dart';

/// Displays full offline details for a single exercise from the bundled
/// 500-exercise catalog — zero network requests and zero API keys.
class ExerciseDetailScreen extends StatelessWidget {
  final String? exerciseId;
  final String name;
  final String muscle;
  final String difficulty;

  const ExerciseDetailScreen({
    super.key,
    this.exerciseId,
    required this.name,
    required this.muscle,
    required this.difficulty,
  });

  Color get muscleColor => ExerciseData.getMuscleColor(muscle);
  IconData get muscleIcon => ExerciseData.getMuscleIcon(muscle);
  IconData get difficultyIcon => ExerciseData.getDifficultyIcon(difficulty);
  Color get difficultyColor => ExerciseData.getDifficultyColor(difficulty);

  ExerciseItem? get _item =>
      ExerciseService.findByIdOrName(id: exerciseId, name: name);

  String? get equipment => _item?.equipment;
  String? get target => _item?.target;
  String? get description => _item?.description;
  String get category => _item?.category ?? 'strength';
  List<String> get localInstructions => _item?.instructions ?? const <String>[];
  List<String> get secondaryMuscles =>
      _item?.secondaryMuscles ?? const <String>[];

  String get recommendedSets {
    switch (difficulty) {
      case 'Beginner':
        return '2-3';
      case 'Intermediate':
        return '3-4';
      case 'Advanced':
        return '4-5';
      default:
        return '3-4';
    }
  }

  String get recommendedReps {
    if (muscle == 'Cardio' || category == 'cardio') return '30-60s';
    if (category == 'stretching' || category == 'mobility') return '20-40s';
    if (muscle == 'Core') {
      switch (difficulty) {
        case 'Beginner':
          return '15-25';
        case 'Intermediate':
          return '20-35';
        default:
          return '25-45';
      }
    }
    switch (difficulty) {
      case 'Beginner':
        return '10-15';
      case 'Intermediate':
        return '8-12';
      case 'Advanced':
        return '6-10';
      default:
        return '8-12';
    }
  }

  String get recommendedRest {
    switch (difficulty) {
      case 'Beginner':
        return '60s';
      case 'Intermediate':
        return '75s';
      case 'Advanced':
        return '90s';
      default:
        return '60s';
    }
  }

  String get fallbackInstructions {
    switch (name) {
      case 'Push-ups':
        return '1. Start in a plank position with hands slightly wider than shoulders.\n\n'
            '2. Keep your body in a straight line from head to heels.\n\n'
            '3. Lower your body until your chest nearly touches the floor.\n\n'
            '4. Push yourself back up to the starting position.\n\n'
            '5. Repeat for desired reps.';
      case 'Squats':
        return '1. Stand with feet shoulder-width apart, toes slightly out.\n\n'
            '2. Keep your chest up and core engaged.\n\n'
            '3. Lower your body by bending knees and pushing hips back.\n\n'
            '4. Go down until thighs are parallel to the floor.\n\n'
            '5. Push through your heels to return to standing.';
      case 'Plank':
        return '1. Start on your forearms and toes.\n\n'
            '2. Keep your body in a straight line.\n\n'
            '3. Engage your core and squeeze your glutes.\n\n'
            '4. Hold without letting hips sag or rise.\n\n'
            '5. Breathe steadily throughout the hold.';
      default:
        return '1. Set up in a stable starting posture.\n\n'
            '2. Brace your core throughout the movement.\n\n'
            '3. Move smoothly through the full range of motion.\n\n'
            '4. Control the eccentric phase on the way back.\n\n'
            '5. Breathe steadily and prioritize form.';
    }
  }

  List<Map<String, Object>> get proTips {
    if (category == 'stretching' || category == 'mobility') {
      return <Map<String, Object>>[
        <String, Object>{
          'title': 'Ease Into Range',
          'description': 'Move to a gentle stretch — never force through pain.',
          'icon': Icons.self_improvement,
          'color': PUI.mint,
        },
        <String, Object>{
          'title': 'Slow Breathing',
          'description': 'Long exhales help muscles relax deeper into posture.',
          'icon': Icons.air,
          'color': PUI.primary,
        },
      ];
    }
    return <Map<String, Object>>[
      <String, Object>{
        'title': 'Control the Eccentric',
        'description': 'Lower under control instead of dropping the weight.',
        'icon': Icons.check_circle,
        'color': PUI.mint,
      },
      <String, Object>{
        'title': 'Brace & Breathe',
        'description': 'Exhale through the hardest part of the lift.',
        'icon': Icons.air,
        'color': PUI.primary,
      },
      <String, Object>{
        'title': 'Progressive Overload',
        'description': 'Add a rep or small load once all target sets feel clean.',
        'icon': Icons.trending_up,
        'color': PUI.amber,
      },
    ];
  }

  Map<String, List<String>> get musclesWorked {
    final primaryList = <String>[
      if (target != null && target!.isNotEmpty)
        titleCaseWords(target!)
      else
        muscle,
    ];
    return <String, List<String>>{
      'Primary': primaryList,
      if (secondaryMuscles.isNotEmpty) 'Secondary': secondaryMuscles,
    };
  }

  RoutineExercise _toRoutineExercise() {
    final item = _item;
    if (item != null) return item.toRoutineExercise();
    return RoutineExercise(
      exerciseId: exerciseId,
      name: name,
      muscle: muscle,
      difficulty: difficulty,
      sets: 3,
      targetReps: 10,
    );
  }

  void _quickStart(BuildContext context) {
    final exerciseMap = _toRoutineExercise().toMap();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VibeCheckSheet(
          originalExercises: <Map<String, dynamic>>[exerciseMap],
          workoutName: name,
        ),
      ),
    );
  }

  void _showAddToWorkoutSheet(BuildContext parentContext) {
    final routines = CustomWorkoutStorage.getAllRoutines();

    unawaited(
      showModalBottomSheet<void>(
        context: parentContext,
        backgroundColor: PUI.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Add to Workout',
              style: PUI.text(size: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Where do you want to put $name?',
              style: PUI.text(
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            if (routines.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No custom workouts yet. Create one below!',
                    style: PUI.text(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: routines.length,
                  itemBuilder: (BuildContext itemContext, int i) {
                    final routine = routines[i];
                    final alreadyHas = routine.exercises.any(
                      (RoutineExercise e) =>
                          e.name.toLowerCase() == name.toLowerCase(),
                    );
                    return Pressable(
                      onTap: () async {
                        final sheetNavigator = Navigator.of(sheetContext);
                        final messenger = ScaffoldMessenger.of(parentContext);
                        if (alreadyHas) {
                          sheetNavigator.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '$name is already in ${routine.name}.',
                              ),
                            ),
                          );
                          return;
                        }
                        final updated = routine.copyWith(
                          exercises: <RoutineExercise>[
                            ...routine.exercises,
                            _toRoutineExercise(),
                          ],
                        );
                        await CustomWorkoutStorage.saveRoutine(updated);
                        if (!parentContext.mounted) return;
                        sheetNavigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added to ${routine.name}!',
                              style: PUI.text(
                                color: Colors.black,
                                weight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: PUI.mint,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.fitness_center,
                              color: PUI.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                routine.name,
                                style: PUI.text(weight: FontWeight.w700),
                              ),
                            ),
                            Icon(
                              alreadyHas
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: PUI.mint,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  unawaited(_createNewWorkoutWithExercise(parentContext));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PUI.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Create New Workout',
                  style: PUI.text(weight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(sheetContext).padding.bottom),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _createNewWorkoutWithExercise(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => const _NewWorkoutNameDialog(),
    );

    final trimmed = newName?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final routine = WorkoutRoutine(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      exercises: <RoutineExercise>[_toRoutineExercise()],
      createdAt: DateTime.now().toIso8601String(),
    );
    await CustomWorkoutStorage.saveRoutine(routine);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "Created '$trimmed' with $name!",
          style: PUI.text(color: Colors.black, weight: FontWeight.w700),
        ),
        backgroundColor: PUI.mint,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'Exercise',
      actions: <Widget>[
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: difficultyColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: difficultyColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(difficultyIcon, color: difficultyColor, size: 14),
              const SizedBox(width: 6),
              Text(
                difficulty,
                style: PUI.text(
                  size: 12,
                  weight: FontWeight.w700,
                  color: difficultyColor,
                ),
              ),
            ],
          ),
        ),
      ],
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 8),
                  _buildExerciseHeroBanner(),
                  const SizedBox(height: 20),
                  GradientText(name, size: 28, weight: FontWeight.w900),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      if (equipment != null && equipment!.isNotEmpty)
                        _buildInfoChip(
                          Icons.construction,
                          titleCaseWords(equipment!),
                        ),
                      if (target != null && target!.isNotEmpty)
                        _buildInfoChip(
                          Icons.track_changes,
                          titleCaseWords(target!),
                        ),
                      _buildInfoChip(
                        Icons.category_outlined,
                        titleCaseWords(category),
                      ),
                    ],
                  ),
                  if (description != null && description!.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Text(
                      description!,
                      style: PUI.text(
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildStatCard(
                          recommendedSets,
                          'Sets',
                          Icons.repeat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          recommendedReps,
                          'Reps',
                          Icons.fitness_center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          recommendedRest,
                          'Rest',
                          Icons.timer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Muscles Worked'),
                  const SizedBox(height: 12),
                  Glass(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: musclesWorked.entries.map(
                        (MapEntry<String, List<String>> entry) {
                          final isPrimary = entry.key == 'Primary';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 84,
                                  child: Text(
                                    entry.key,
                                    style: PUI.text(
                                      size: 13,
                                      weight: FontWeight.w700,
                                      color: isPrimary
                                          ? muscleColor
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: entry.value
                                        .map(
                                          (String m) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPrimary
                                                  ? muscleColor.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : Colors.white.withValues(
                                                      alpha: 0.06,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              m,
                                              style: PUI.text(
                                                size: 12,
                                                weight: FontWeight.w600,
                                                color: isPrimary
                                                    ? muscleColor
                                                    : Colors.white.withValues(
                                                        alpha: 0.7,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Form Instructions'),
                  const SizedBox(height: 12),
                  Glass(
                    radius: 20,
                    padding: const EdgeInsets.all(20),
                    child: localInstructions.isNotEmpty
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              for (
                                int i = 0;
                                i < localInstructions.length;
                                i++
                              )
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i == localInstructions.length - 1
                                        ? 0
                                        : 14,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: muscleColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${i + 1}',
                                          style: PUI.text(
                                            size: 12,
                                            weight: FontWeight.w800,
                                            color: muscleColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          localInstructions[i],
                                          style: PUI.text(
                                            size: 14,
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          )
                        : Text(
                            fallbackInstructions,
                            style: PUI.text(
                              size: 15,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.6,
                            ),
                          ),
                  ),
                  const SizedBox(height: 28),
                  const SectionTitle('Pro Tips'),
                  const SizedBox(height: 12),
                  ...proTips.map(
                    (Map<String, Object> tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildTipCard(
                        tip['title']! as String,
                        tip['description']! as String,
                        tip['icon']! as IconData,
                        tip['color']! as Color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Pressable(
                    onTap: () => _quickStart(context),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: muscleColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: muscleColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.play_arrow,
                              color: muscleColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quick Start',
                              style: PUI.text(
                                size: 14,
                                weight: FontWeight.w800,
                                color: muscleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Pressable(
                    onTap: () => _showAddToWorkoutSheet(context),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            muscleColor,
                            muscleColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: muscleColor.withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.add_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Add to Workout',
                              style: PUI.text(
                                size: 15,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: PUI.mint, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: PUI.text(
              size: 12,
              weight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseHeroBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[PUI.surface, PUI.bg],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: muscleColor.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: muscleColor.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: _GridPainter(
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: muscleColor.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.local_fire_department,
                    color: muscleColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Target: $muscle',
                    style: PUI.text(
                      size: 12,
                      weight: FontWeight.w700,
                      color: muscleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: muscleColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    muscleIcon,
                    size: 52,
                    color: muscleColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  target != null && target!.isNotEmpty
                      ? '${titleCaseWords(target!)} Focus'
                      : '$muscle Movement',
                  style: PUI.text(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: <Widget>[
          Icon(icon, color: muscleColor, size: 22),
          const SizedBox(height: 8),
          GradientText(
            value,
            size: 18,
            colors: <Color>[Colors.white, muscleColor],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: PUI.text(
              size: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    String title,
    String descriptionText,
    IconData icon,
    Color color,
  ) {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: PUI.text(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  descriptionText,
                  style: PUI.text(
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewWorkoutNameDialog extends StatefulWidget {
  const _NewWorkoutNameDialog();

  @override
  State<_NewWorkoutNameDialog> createState() => _NewWorkoutNameDialogState();
}

class _NewWorkoutNameDialogState extends State<_NewWorkoutNameDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PUI.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'New Workout',
        style: PUI.text(size: 20, weight: FontWeight.w700),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: 'e.g. Push Day',
          hintStyle: PUI.text(color: Colors.white38),
        ),
        style: PUI.text(),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: PUI.text(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: PUI.primary),
          child: Text('Create', style: PUI.text(weight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const spacing = 20.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
