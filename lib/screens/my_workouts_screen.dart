import 'dart:async';

import 'package:flutter/material.dart';

import '../core/event_bus.dart';
import '../core/premium_ui.dart';
import '../models/workout_models.dart';
import '../services/storage_services.dart';
import '../widgets/vibe_check_sheet.dart';
import 'workout_builder_screen.dart';

class MyWorkoutsScreen extends StatefulWidget {
  const MyWorkoutsScreen({super.key});

  @override
  State<MyWorkoutsScreen> createState() => _MyWorkoutsScreenState();
}

class _MyWorkoutsScreenState extends State<MyWorkoutsScreen> {
  List<WorkoutRoutine> _routines = <WorkoutRoutine>[];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    WorkoutEventBus.instance.revision.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    if (mounted) _loadWorkouts();
  }

  @override
  void dispose() {
    WorkoutEventBus.instance.revision.removeListener(_onDataChanged);
    super.dispose();
  }

  void _loadWorkouts() {
    setState(() {
      _routines = CustomWorkoutStorage.getAllRoutines();
    });
  }

  void _startRoutine(WorkoutRoutine routine) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VibeCheckSheet(
          originalExercises: routine.exercises
              .map((RoutineExercise e) => e.toMap())
              .toList(),
          workoutName: routine.name,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(WorkoutRoutine routine) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: PUI.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Routine?',
          style: PUI.text(size: 20, weight: FontWeight.w800),
        ),
        content: Text(
          "Delete '${routine.name}'? Any split days assigned to it will revert to Rest Day.",
          style: PUI.text(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: PUI.text(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: PUI.flame),
            child: Text('Delete', style: PUI.text(weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await CustomWorkoutStorage.deleteCustomWorkout(routine.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text("Deleted '${routine.name}'."),
        backgroundColor: PUI.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      aurora: true,
      title: 'My Workouts',
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            tooltip: 'Create Workout',
            icon: const Icon(Icons.add_circle, color: PUI.primary, size: 28),
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const WorkoutBuilderScreen(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
      body: _routines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: PUI.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No custom workouts yet',
                      style: PUI.text(size: 18, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a custom routine or add exercises from the Library!',
                      style: PUI.text(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 220,
                      child: PrimaryButton(
                        label: 'Create Workout',
                        icon: Icons.add,
                        height: 52,
                        onTap: () {
                          unawaited(
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const WorkoutBuilderScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _routines.length,
              itemBuilder: (BuildContext context, int i) {
                final routine = _routines[i];
                final exercises = routine.exercises;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Pressable(
                    onTap: () => _startRoutine(routine),
                    child: Glass(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  routine.name,
                                  style: PUI.text(
                                    size: 20,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit Routine',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: PUI.primary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  unawaited(
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => WorkoutBuilderScreen(
                                          existingWorkout: routine.toMap(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                tooltip: 'Delete Routine',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: PUI.flame,
                                  size: 20,
                                ),
                                onPressed: () => _confirmDelete(routine),
                              ),
                            ],
                          ),
                          if (routine.description.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              routine.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: PUI.text(
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            '${exercises.length} exercise${exercises.length == 1 ? '' : 's'}',
                            style: PUI.text(
                              size: 14,
                              color: PUI.primary,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              ...exercises.take(3).map(
                                (RoutineExercise ex) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    ex.name,
                                    style: PUI.text(
                                      size: 12,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              if (exercises.length > 3)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: PUI.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+${exercises.length - 3} more',
                                    style: PUI.text(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: PUI.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
