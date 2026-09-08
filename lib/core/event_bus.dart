import 'package:flutter/foundation.dart';

/// A simple, dependency-free event bus for broadcasting workout-related
/// changes across the app. Screens that care about workout data (like
/// the HomeScreen) subscribe to the revision counter, and storage
/// classes bump the counter whenever they mutate data.
class WorkoutEventBus {
  WorkoutEventBus._();
  static final WorkoutEventBus instance = WorkoutEventBus._();

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  /// Listen to this to get notified when any workout data changes.
  ValueNotifier<int> get revision => _revision;

  /// Call whenever a workout is saved, deleted, or cleared.
  void notifyWorkoutChanged() {
    _revision.value++;
  }

  /// Call when custom workouts are modified.
  void notifyCustomWorkoutsChanged() {
    _revision.value++;
  }

  /// Call when settings that affect the home screen change.
  void notifySettingsChanged() {
    _revision.value++;
  }
}