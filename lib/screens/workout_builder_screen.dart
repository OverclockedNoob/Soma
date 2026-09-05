import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'exercise_picker_screen.dart';
import 'active_workout_screen.dart';
import '../core/premium_ui.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final Map<String, dynamic>? existingWorkout; // For editing later

  const WorkoutBuilderScreen({super.key, this.existingWorkout});

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  List<Map<String, dynamic>> selectedExercises = [];
  String? workoutId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingWorkout?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.existingWorkout?['description'] ?? '');

    if (widget.existingWorkout != null) {
      workoutId = widget.existingWorkout!['id'];
      selectedExercises = (widget.existingWorkout!['exercises'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addExercise() async {
    final alreadyAddedNames = selectedExercises.map((e) => e['name'] as String).toList();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExercisePickerScreen(alreadyAdded: alreadyAddedNames),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        selectedExercises.add({
          'name': result['name'],
          'muscle': result['muscle'],
          'difficulty': result['difficulty'],
          'sets': 3,
          'targetReps': 10,
        });
      });
    }
  }

  void _removeExercise(int index) {
    setState(() => selectedExercises.removeAt(index));
  }

  void _editExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => _EditExerciseDialog(
        exercise: selectedExercises[index],
        onSave: (updated) => setState(() => selectedExercises[index] = updated),
      ),
    );
  }

  void _saveWorkout() async {
    if (_nameController.text.trim().isEmpty || selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add a name and at least one exercise!', style: PUI.text())),
      );
      return;
    }

    setState(() => _isSaving = true);

    final workout = {
      'id': workoutId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'exercises': selectedExercises,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await CustomWorkoutStorage.saveCustomWorkout(workout);
    if (!mounted) return;

    setState(() => _isSaving = false);
    Navigator.pop(context, true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${workout['name']} saved!', style: PUI.text(weight: FontWeight.w700)),
        backgroundColor: PUI.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: widget.existingWorkout == null ? 'Create Workout' : 'Edit Workout',
      actions: [
        _isSaving
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: PUI.primary, strokeWidth: 2),
                ),
              )
            : Pressable(
                onTap: _saveWorkout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Save', style: PUI.text(color: PUI.mint, size: 16, weight: FontWeight.w800)),
                ),
              ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── NAME INPUT ────────────────────────
            Text('Workout Name', style: PUI.text(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.6))),
            const SizedBox(height: 8),
            Glass(
              radius: 16,
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _nameController,
                style: PUI.text(size: 16, weight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g., Push Day, Full Body',
                  hintStyle: PUI.text(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── DESCRIPTION INPUT ─────────────────
            Text('Description (Optional)', style: PUI.text(size: 14, weight: FontWeight.w700, color: Colors.white.withOpacity(0.6))),
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
                  hintStyle: PUI.text(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── EXERCISES HEADER ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle("Exercises"),
                Text(
                  '${selectedExercises.length}/20',
                  style: PUI.text(color: Colors.white.withOpacity(0.5), size: 14, weight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── ADD EXERCISE BUTTON ───────────────
            Pressable(
              onTap: selectedExercises.length >= 20 ? null : _addExercise,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PUI.primary.withOpacity(0.4), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: PUI.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      selectedExercises.length >= 20 ? 'Maximum reached' : 'Add Exercise',
                      style: PUI.text(color: PUI.primary, size: 16, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── EXERCISE LIST ─────────────────────
            if (selectedExercises.isEmpty)
              Glass(
                radius: 24,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    Text('No exercises added yet', style: PUI.text(color: Colors.white.withOpacity(0.5), size: 16)),
                  ],
                ),
              )
            else
              ...selectedExercises.asMap().entries.map((entry) {
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: PUI.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fitness_center, color: PUI.primary, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exercise['name'], style: PUI.text(size: 16, weight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  '${exercise['sets']} sets × ${exercise['targetReps']} reps',
                                  style: PUI.text(size: 13, color: Colors.white.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                          Pressable(
                            onTap: () => _editExercise(index),
                            child: Icon(Icons.edit_outlined, color: PUI.primary, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Pressable(
                            onTap: () => _removeExercise(index),
                            child: Icon(Icons.delete_outline, color: PUI.flame, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 32),

            // ── START WORKOUT BUTTON ──────────────
            if (selectedExercises.isNotEmpty)
              PrimaryButton(
                label: "Start This Workout",
                icon: Icons.play_arrow_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveWorkoutScreen(customExercises: selectedExercises),
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

// ── PREMIUM EDIT EXERCISE DIALOG ───────────────────────────────────
class _EditExerciseDialog extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final Function(Map<String, dynamic>) onSave;

  const _EditExerciseDialog({required this.exercise, required this.onSave});

  @override
  State<_EditExerciseDialog> createState() => _EditExerciseDialogState();
}

class _EditExerciseDialogState extends State<_EditExerciseDialog> {
  late int sets;
  late int targetReps;

  @override
  void initState() {
    super.initState();
    sets = widget.exercise['sets'] ?? 3;
    targetReps = widget.exercise['targetReps'] ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PUI.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(widget.exercise['name'], style: PUI.text(size: 20, weight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounter('Sets', sets, (v) => setState(() => sets = v)),
          const SizedBox(height: 16),
          _buildCounter('Target Reps', targetReps, (v) => setState(() => targetReps = v)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: PUI.text(color: Colors.white.withOpacity(0.5))),
        ),
        ElevatedButton(
          onPressed: () {
            final updated = Map<String, dynamic>.from(widget.exercise);
            updated['sets'] = sets;
            updated['targetReps'] = targetReps;
            widget.onSave(updated);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: PUI.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Save', style: PUI.text(weight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: PUI.text(size: 16, weight: FontWeight.w600)),
        Glass(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Pressable(
                onTap: value > 1 ? () => onChanged(value - 1) : null,
                child: Icon(Icons.remove_circle_outline, color: value > 1 ? PUI.primary : Colors.white24, size: 28),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('$value', style: PUI.text(size: 18, weight: FontWeight.w800)),
              ),
              Pressable(
                onTap: () => onChanged(value + 1),
                child: Icon(Icons.add_circle_outline, color: PUI.primary, size: 28),
              ),
            ],
          ),
        ),
      ],
    );
  }
}