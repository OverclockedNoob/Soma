import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/premium_ui.dart';
import '../data/exercise_data.dart';
import '../models/workout_models.dart';
import '../services/exercise_service.dart';
import '../services/storage_services.dart';
import 'workout_summary_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? customExercises;
  final String workoutName;

  const ActiveWorkoutScreen({
    super.key,
    this.customExercises,
    this.workoutName = 'Quick Workout',
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  late List<RoutineExercise> exercises;
  int currentExerciseIndex = 0;

  /// Key format: `"exerciseIdx_setIdx"` -> completed rep count.
  final Map<String, int> completedSets = <String, int>{};

  Timer? _stopwatchTimer;
  int elapsedSeconds = 0;
  late final DateTime _workoutStartTime;
  bool _isFinishing = false;

  static const List<Map<String, dynamic>> _defaultExercises =
      <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'Push-ups',
          'muscle': 'Chest',
          'difficulty': 'Beginner',
          'sets': 3,
          'targetReps': 12,
        },
        <String, dynamic>{
          'name': 'Squats',
          'muscle': 'Legs',
          'difficulty': 'Beginner',
          'sets': 4,
          'targetReps': 10,
        },
        <String, dynamic>{
          'name': 'Plank',
          'muscle': 'Core',
          'difficulty': 'Beginner',
          'sets': 3,
          'targetReps': 30,
        },
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final rawList = (widget.customExercises == null ||
            widget.customExercises!.isEmpty)
        ? _defaultExercises
        : widget.customExercises!;

    exercises = rawList.map(RoutineExercise.fromMap).toList();
    _workoutStartTime = DateTime.now();
    _startStopwatch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _syncElapsedTime();
    }
  }

  void _syncElapsedTime() {
    final seconds = DateTime.now().difference(_workoutStartTime).inSeconds;
    if (seconds != elapsedSeconds) {
      setState(() => elapsedSeconds = seconds < 0 ? 0 : seconds);
    }
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _syncElapsedTime();
    });
  }

  String get _formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _playFeedback() {
    if (SettingsStorage.getSoundEffects()) {
      unawaited(SystemSound.play(SystemSoundType.click));
    }
    unawaited(HapticFeedback.lightImpact());
  }

  void _toggleSet(int exerciseIdx, int setIdx, int targetReps) {
    final key = '${exerciseIdx}_$setIdx';
    _playFeedback();
    setState(() {
      if (completedSets.containsKey(key)) {
        completedSets.remove(key);
      } else {
        completedSets[key] = targetReps;
      }
    });
  }

  Future<void> _editSetReps(
    int exerciseIdx,
    int setIdx,
    int targetReps,
  ) async {
    final key = '${exerciseIdx}_$setIdx';
    final initialReps = completedSets[key] ?? targetReps;

    final newReps = await showDialog<int>(
      context: context,
      builder: (_) => _EditRepsDialog(initialReps: initialReps),
    );

    if (newReps == null || !mounted) return;
    setState(() {
      if (newReps > 0) {
        completedSets[key] = newReps;
      } else {
        completedSets.remove(key);
      }
    });
  }

  bool _isSetCompleted(int exerciseIdx, int setIdx) =>
      completedSets.containsKey('${exerciseIdx}_$setIdx');

  int _getSetReps(int exerciseIdx, int setIdx) =>
      completedSets['${exerciseIdx}_$setIdx'] ?? 0;

  void _previousExercise() {
    if (currentExerciseIndex > 0) {
      setState(() => currentExerciseIndex--);
    }
  }

  void _nextExercise() {
    if (currentExerciseIndex < exercises.length - 1) {
      setState(() => currentExerciseIndex++);
    } else {
      unawaited(_finishWorkout());
    }
  }

  /// MET-based calorie estimate scaled by body weight, exact elapsed hours,
  /// and a gentle age metabolic factor from SettingsStorage.
  int _calculateCalories(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds <= 0 || exercises.isEmpty) return 0;

    final weight = SettingsStorage.getWeight();
    final age = SettingsStorage.getAge();
    final ageFactor = (1.0 - ((age - 25) * 0.002)).clamp(0.82, 1.08);

    double totalMet = 0;
    for (final ex in exercises) {
      totalMet += _getMetForExercise(ex.name, ex.muscle);
    }
    final avgMet = totalMet / exercises.length;
    final hours = seconds / 3600.0;

    final kcal = (avgMet * weight * hours * ageFactor).round();
    return kcal < 1 && completedSets.isNotEmpty ? 1 : kcal;
  }

  double _getMetForExercise(String name, String muscle) {
    final lower = name.toLowerCase();
    if (lower.contains('run') ||
        lower.contains('sprint') ||
        lower.contains('burpee') ||
        lower.contains('hiit')) {
      return 9.0;
    }
    if (muscle == 'Cardio' ||
        lower.contains('cardio') ||
        lower.contains('bike') ||
        lower.contains('jump')) {
      return 8.0;
    }
    if (lower.contains('squat') ||
        lower.contains('deadlift') ||
        lower.contains('clean') ||
        lower.contains('snatch')) {
      return 7.0;
    }
    if (lower.contains('push') ||
        lower.contains('press') ||
        lower.contains('pull') ||
        lower.contains('row')) {
      return 6.0;
    }
    if (lower.contains('plank') ||
        lower.contains('crunch') ||
        lower.contains('stretch') ||
        muscle == 'Core') {
      return 3.8;
    }
    return 5.0;
  }

  Future<void> _finishWorkout() async {
    if (_isFinishing) return;

    if (completedSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Log at least one set before finishing, or tap × to quit.',
            style: PUI.text(weight: FontWeight.w600),
          ),
          backgroundColor: PUI.flame,
        ),
      );
      return;
    }

    setState(() => _isFinishing = true);
    _stopwatchTimer?.cancel();

    final now = DateTime.now();
    final duration = now.difference(_workoutStartTime);
    final dateStr = formatDateKey(now);

    final sortedEntries = completedSets.entries.toList()
      ..sort((MapEntry<String, int> a, MapEntry<String, int> b) {
        final partsA = a.key.split('_');
        final partsB = b.key.split('_');
        final exCmp = int.parse(partsA[0]).compareTo(int.parse(partsB[0]));
        if (exCmp != 0) return exCmp;
        return int.parse(partsA[1]).compareTo(int.parse(partsB[1]));
      });

    final finalCompletedSets = <CompletedSet>[];
    int totalReps = 0;

    for (final entry in sortedEntries) {
      final parts = entry.key.split('_');
      final exIdx = int.parse(parts[0]);
      final setIdx = int.parse(parts[1]);
      final reps = entry.value;

      finalCompletedSets.add(
        CompletedSet(
          exerciseIndex: exIdx,
          exercise: exercises[exIdx].name,
          setNumber: setIdx + 1,
          reps: reps,
        ),
      );
      totalReps += reps;
    }

    final estimatedCalories = _calculateCalories(duration);
    final durationMins = duration.inSeconds >= 30 && duration.inMinutes == 0
        ? 1
        : duration.inMinutes;

    final session = WorkoutSession(
      id: now.microsecondsSinceEpoch.toString(),
      name: widget.workoutName,
      date: dateStr,
      durationSeconds: duration.inSeconds,
      durationMinutes: durationMins,
      calories: estimatedCalories,
      totalSets: finalCompletedSets.length,
      totalReps: totalReps,
      exercises: exercises.map((RoutineExercise e) => e.name).toList(),
      sets: finalCompletedSets,
    );

    final saved = await WorkoutStorage.saveWorkoutSession(session);
    if (saved) {
      await SettingsStorage.addRecoveryCoins(1);
      _playFeedback();
    }

    if (!mounted) return;

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save workout — check local storage."),
        ),
      );
    }

    final exerciseMaps =
        exercises.map((RoutineExercise e) => e.toMap()).toList();
    final setMaps =
        finalCompletedSets.map((CompletedSet s) => s.toMap()).toList();

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WorkoutSummaryScreen(
          workoutName: widget.workoutName,
          completedSets: setMaps,
          duration: duration,
          exercises: exerciseMaps,
          calories: estimatedCalories,
          coinEarned: saved,
        ),
      ),
    );
  }

  void _showPivotDialog() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: PUI.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gym Tetris 🔄',
              style: PUI.text(size: 22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Equipment busy? Swap to a matching local exercise:',
              style: PUI.text(
                size: 14,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildEquipmentButton(
              sheetContext,
              'Dumbbells',
              Icons.fitness_center,
              PUI.pink,
            ),
            const SizedBox(height: 12),
            _buildEquipmentButton(
              sheetContext,
              'Machine / Cable',
              Icons.precision_manufacturing_outlined,
              PUI.mint,
            ),
            const SizedBox(height: 12),
            _buildEquipmentButton(
              sheetContext,
              'Bodyweight Only',
              Icons.accessibility_new,
              PUI.amber,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEquipmentButton(
    BuildContext sheetContext,
    String label,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(sheetContext);
          _swapExercise(label);
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: PUI.text(size: 15, weight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  void _swapExercise(String equipmentChoice) {
    final current = exercises[currentExerciseIndex];
    final existingNames = exercises
        .map((RoutineExercise e) => e.name)
        .toSet();

    final swapped = ExerciseService.findSubstitute(
      current: current,
      equipmentChoice: equipmentChoice,
      excludedNames: existingNames,
    );

    setState(() {
      exercises[currentExerciseIndex] = swapped;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.sync, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Swapped to ${swapped.name}!',
                style: PUI.text(weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: PUI.primary,
      ),
    );
  }

  Future<void> _confirmQuit() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: PUI.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Quit Workout?',
          style: PUI.text(size: 20, weight: FontWeight.w800),
        ),
        content: Text(
          'Your unlogged progress for this session will be discarded.',
          style: PUI.text(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Continue',
              style: PUI.text(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Quit',
              style: PUI.text(color: PUI.flame, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (shouldQuit == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = exercises[currentExerciseIndex];
    final exerciseColor = ExerciseData.getMuscleColor(exercise.muscle);
    final totalSetsInWorkout = exercises.fold<int>(
      0,
      (int sum, RoutineExercise e) => sum + e.sets,
    );
    final completedSetsCount = completedSets.length;
    final progress = totalSetsInWorkout > 0
        ? (completedSetsCount / totalSetsInWorkout).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: PUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _confirmQuit,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.timer_outlined,
                  color: PUI.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _formattedTime,
                  style: PUI.text(size: 18, weight: FontWeight.w800),
                ),
              ],
            ),
            Text(
              widget.workoutName,
              style: PUI.text(
                size: 11,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: <Widget>[
          const AuroraBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(exerciseColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Exercise ${currentExerciseIndex + 1} of ${exercises.length}',
                        style: PUI.text(
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 13,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}% Complete',
                        style: PUI.text(
                          color: exerciseColor,
                          size: 13,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (exercises.length > 1) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: exercises.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (BuildContext context, int idx) {
                          final active = idx == currentExerciseIndex;
                          return Pressable(
                            onTap: () =>
                                setState(() => currentExerciseIndex = idx),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? exerciseColor.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? exerciseColor
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                '${idx + 1}. ${exercises[idx].name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PUI.text(
                                  size: 11,
                                  weight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              exercise.name,
                              style: PUI.text(
                                size: 26,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${exercise.sets} Sets × ${exercise.targetReps} Reps • ${exercise.muscle}',
                              style: PUI.text(
                                color: Colors.white.withValues(alpha: 0.55),
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pressable(
                        onTap: _showPivotDialog,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: exerciseColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: exerciseColor.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.sync,
                            color: exerciseColor,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: exercise.sets + 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == exercise.sets) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Pressable(
                              onTap: () {
                                setState(() {
                                  exercises[currentExerciseIndex] =
                                      exercise.copyWith(
                                        sets: exercise.sets + 1,
                                      );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: exerciseColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: exerciseColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Set',
                                      style: PUI.text(
                                        color: exerciseColor,
                                        weight: FontWeight.w700,
                                        size: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        final isCompleted = _isSetCompleted(
                          currentExerciseIndex,
                          index,
                        );
                        final reps = _getSetReps(currentExerciseIndex, index);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => _toggleSet(
                              currentExerciseIndex,
                              index,
                              exercise.targetReps,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: PUI.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCompleted
                                      ? exerciseColor
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: isCompleted ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? exerciseColor
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isCompleted
                                            ? exerciseColor
                                            : Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                        width: 2,
                                      ),
                                    ),
                                    child: isCompleted
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Set ${index + 1}',
                                    style: PUI.text(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      size: 16,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _editSetReps(
                                      currentExerciseIndex,
                                      index,
                                      exercise.targetReps,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            isCompleted
                                                ? '$reps reps'
                                                : '${exercise.targetReps} reps',
                                            style: PUI.text(
                                              color: isCompleted
                                                  ? exerciseColor
                                                  : Colors.white.withValues(
                                                      alpha: 0.55,
                                                    ),
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: Colors.white.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ],
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
                  Row(
                    children: <Widget>[
                      if (currentExerciseIndex > 0) ...<Widget>[
                        Pressable(
                          onTap: _previousExercise,
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Prev',
                                    style: PUI.text(
                                      size: 15,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                exerciseColor,
                                exerciseColor.withValues(alpha: 0.72),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: exerciseColor.withValues(alpha: 0.38),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isFinishing ? null : _nextExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              currentExerciseIndex < exercises.length - 1
                                  ? 'Next Exercise →'
                                  : 'Finish Workout',
                              style: PUI.text(
                                size: 17,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRepsDialog extends StatefulWidget {
  final int initialReps;

  const _EditRepsDialog({required this.initialReps});

  @override
  State<_EditRepsDialog> createState() => _EditRepsDialogState();
}

class _EditRepsDialogState extends State<_EditRepsDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialReps.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim()) ?? 0;
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PUI.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Edit Reps',
        style: PUI.text(size: 20, weight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        textAlign: TextAlign.center,
        style: PUI.text(size: 26, weight: FontWeight.w800),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: PUI.text(color: Colors.white30, size: 26),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: PUI.primary.withValues(alpha: 0.4)),
          ),
        ),
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
          child: Text('Save', style: PUI.text(weight: FontWeight.w700)),
        ),
      ],
    );
  }
}
