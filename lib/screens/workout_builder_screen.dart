import 'dart:async';

import 'package:flutter/material.dart';

import '../core/premium_ui.dart';
import '../models/workout_models.dart';
import '../services/storage_services.dart';
import '../widgets/vibe_check_sheet.dart';
import 'exercise_picker_screen.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final Map<String, dynamic>? existingWorkout;

  const WorkoutBuilderScreen({super.key, this.existingWorkout});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  List<RoutineExercise> selectedExercises = <RoutineExercise>[];
  String? workoutId;
  String? _createdAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingWorkout;
    _nameController = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );

    if (existing != null) {
      final routine = WorkoutRoutine.fromMap(existing);
      workoutId = routine.id.isEmpty ? null : routine.id;
      _createdAt = routine.createdAt.isEmpty ? null : routine.createdAt;
      selectedExercises = List<RoutineExercise>.from(routine.exercises);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final alreadyAddedNames = selectedExercises
        .map((RoutineExercise e) => e.name)
        .toList();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => ExercisePickerScreen(alreadyAdded: alreadyAddedNames),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        selectedExercises.add(
          RoutineExercise(
            exerciseId: result['exerciseId']?.toString(),
            name: result['name']?.toString() ?? 'Exercise',
            muscle: result['muscle']?.toString() ?? 'Core',
            difficulty: result['difficulty']?.toString() ?? 'Intermediate',
            equipment: result['equipment']?.toString(),
            sets: 3,
            targetReps: 10,
          ),
        );
      });
    }
  }

  void _removeExercise(int index) {
    setState(() => selectedExercises.removeAt(index));
  }

  void _editExercise(int index) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => _EditExerciseDialog(
          exercise: selectedExercises[index],
          onSave: (RoutineExercise updated) =>
              setState(() => selectedExercises[index] = updated),
        ),
      ),
    );
  }

  Future<void> _saveWorkout() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty || selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add a name and at least one exercise!',
            style: PUI.text(),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final routine = WorkoutRoutine(
      id: workoutId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmedName,
      description: _descriptionController.text.trim(),
      exercises: selectedExercises,
      createdAt: _createdAt ?? DateTime.now().toIso8601String(),
    );

    await CustomWorkoutStorage.saveRoutine(routine);
    if (!mounted) return;

    setState(() => _isSaving = false);
    navigator.pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${routine.name} saved!',
          style: PUI.text(weight: FontWeight.w700),
        ),
        backgroundColor: PUI.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: widget.existingWorkout == null ? 'Create Workout' : 'Edit Workout',
      actions: <Widget>[
        _isSaving
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: PUI.primary,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Pressable(
                onTap: _saveWorkout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      'Save',
                      style: PUI.text(
                        color: PUI.mint,
                        size: 16,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Workout Name',
              style: PUI.text(
                size: 14,
                weight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Glass(
              radius: 16,
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _nameController,
                style: PUI.text(size: 16, weight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g., Push Day, Full Body',
                  hintStyle: PUI.text(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Description (Optional)',
              style: PUI.text(
                size: 14,
                weight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Glass(
              radius: 16,
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _descriptionController,
                style: PUI.text(size: 16),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add notes...',
                  hintStyle: PUI.text(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SectionTitle('Exercises'),
                Text(
                  '${selectedExercises.length}/20',
                  style: PUI.text(
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Pressable(
              onTap: selectedExercises.length >= 20 ? null : _addExercise,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: PUI.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.add_circle_outline,
                      color: PUI.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedExercises.length >= 20
                          ? 'Maximum reached'
                          : 'Add Exercise',
                      style: PUI.text(
                        color: PUI.primary,
                        size: 16,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (selectedExercises.isEmpty)
              Glass(
                radius: 24,
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No exercises added yet',
                        style: PUI.text(
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...selectedExercises.asMap().entries.map(
                (MapEntry<int, RoutineExercise> entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Pressable(
                      onTap: () => _editExercise(index),
                      child: Glass(
                        radius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: PUI.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: PUI.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    exercise.name,
                                    style: PUI.text(
                                      size: 16,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${exercise.sets} sets × ${exercise.targetReps} reps',
                                    style: PUI.text(
                                      size: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Pressable(
                              onTap: () => _editExercise(index),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: PUI.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Pressable(
                              onTap: () => _removeExercise(index),
                              child: const Icon(
                                Icons.delete_outline,
                                color: PUI.flame,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            if (selectedExercises.isNotEmpty)
              PrimaryButton(
                label: 'Start This Workout',
                icon: Icons.play_arrow_rounded,
                onTap: () {
                  final rawTitle = _nameController.text.trim();
                  unawaited(
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => VibeCheckSheet(
                        originalExercises: selectedExercises
                            .map((RoutineExercise e) => e.toMap())
                            .toList(),
                        workoutName: rawTitle.isEmpty ? 'Custom Workout' : rawTitle,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _EditExerciseDialog extends StatefulWidget {
  final RoutineExercise exercise;
  final ValueChanged<RoutineExercise> onSave;

  const _EditExerciseDialog({
    required this.exercise,
    required this.onSave,
  });

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  late int sets;
  late int targetReps;

  @override
  void initState() {
    super.initState();
    sets = widget.exercise.sets;
    targetReps = widget.exercise.targetReps;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PUI.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.exercise.name,
        style: PUI.text(size: 20, weight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildCounter('Sets', sets, (int v) => setState(() => sets = v)),
          const SizedBox(height: 16),
          _buildCounter(
            'Target Reps',
            targetReps,
            (int v) => setState(() => targetReps = v),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: PUI.text(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              widget.exercise.copyWith(sets: sets, targetReps: targetReps),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: PUI.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Save', style: PUI.text(weight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: PUI.text(size: 16, weight: FontWeight.w600)),
        Glass(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: <Widget>[
              Pressable(
                onTap: value > 1 ? () => onChanged(value - 1) : null,
                child: Icon(
                  Icons.remove_circle_outline,
                  color: value > 1 ? PUI.primary : Colors.white24,
                  size: 28,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$value',
                  style: PUI.text(size: 18, weight: FontWeight.w800),
                ),
              ),
              Pressable(
                onTap: () => onChanged(value + 1),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: PUI.primary,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
