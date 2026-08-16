import 'package:flutter/material.dart';
import 'package:workout_tracker/services/storage_services.dart';
import 'exercise_picker_screen.dart';
import 'active_workout_screen.dart';

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
    _nameController = TextEditingController(
      text: widget.existingWorkout?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.existingWorkout?['description'] ?? '',
    );

    if (widget.existingWorkout != null) {
      workoutId = widget.existingWorkout!['id'];
      selectedExercises =
          (widget.existingWorkout!['exercises'] as List? ?? [])
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
    final alreadyAddedNames =
        selectedExercises.map((e) => e['name'] as String).toList();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ExercisePickerScreen(alreadyAdded: alreadyAddedNames),
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
      builder:
          (context) => _EditExerciseDialog(
            exercise: selectedExercises[index],
            onSave:
                (updated) => setState(() => selectedExercises[index] = updated),
          ),
    );
  }

  void _saveWorkout() async {
    if (_nameController.text.trim().isEmpty || selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a name and at least one exercise!'),
        ),
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
        content: Text('${workout['name']} saved!'),
        backgroundColor: const Color(0xFF6C5CE7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingWorkout == null ? 'Create Workout' : 'Edit Workout',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF6C5CE7),
                  strokeWidth: 2,
                ),
              )
              : TextButton(
                onPressed: _saveWorkout,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Input
              const Text(
                'Workout Name',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g., Push Day, Full Body',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Description Input
              const Text(
                'Description (Optional)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add notes...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Exercises Header & Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exercises',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${selectedExercises.length}/20',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      selectedExercises.length >= 20 ? null : _addExercise,
                  icon: const Icon(Icons.add, color: Color(0xFF6C5CE7)),
                  label: Text(
                    selectedExercises.length >= 20
                        ? 'Maximum reached'
                        : 'Add Exercise',
                    style: TextStyle(
                      color: const Color(0xFF6C5CE7),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Exercise List
              if (selectedExercises.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E3F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No exercises added yet',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...selectedExercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Color(0xFF6C5CE7),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        exercise['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${exercise['sets']} sets × ${exercise['targetReps']} reps',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF6C5CE7),
                              size: 20,
                            ),
                            onPressed: () => _editExercise(index),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFE91E63),
                              size: 20,
                            ),
                            onPressed: () => _removeExercise(index),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Start Workout Button
              if (selectedExercises.isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF9B59B6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ActiveWorkoutScreen(
                                customExercises: selectedExercises,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Start This Workout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
  }
}

// ── Edit Exercise Dialog ───────────────────────────────────────────
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
      backgroundColor: const Color(0xFF1E1E3F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.exercise['name'],
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounter('Sets', sets, (v) => setState(() => sets = v)),
          const SizedBox(height: 16),
          _buildCounter(
            'Target Reps',
            targetReps,
            (v) => setState(() => targetReps = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
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
            backgroundColor: const Color(0xFF6C5CE7),
          ),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: Icon(
                Icons.remove_circle_outline,
                color: value > 1 ? const Color(0xFF6C5CE7) : Colors.white24,
              ),
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF6C5CE7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Extension to get .asMap() for lists
extension ListExtension<E> on List<E> {
  Iterable<MapEntry<int, E>> asMap() sync* {
    for (var i = 0; i < length; i++) {
      yield MapEntry(i, this[i]);
    }
  }
}
