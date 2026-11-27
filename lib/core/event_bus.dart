import 'package:flutter/foundation.dart';

/// Dependency-free event bus for broadcasting data mutations across screens.
///
/// Screens inside `MainNavigationScreen`'s `IndexedStack` remain mounted for
/// the lifetime of the app, so they subscribe to [revision] to stay in sync
/// whenever workouts, routines, split programs, or settings change.
class WorkoutEventBus {
  WorkoutEventBus._();
  static final WorkoutEventBus instance = WorkoutEventBus._();

  final ValueNotifier<int> _revision = ValueNotifier<int>(0);

  /// Emits an incremented revision number whenever persisted app state changes.
  ValueNotifier<int> get revision => _revision;

  void notifyWorkoutChanged() {
    _revision.value++;
  }

  void notifyCustomWorkoutsChanged() {
    _revision.value++;
  }

  void notifyProgramsChanged() {
    _revision.value++;
  }

  void notifySettingsChanged() {
    _revision.value++;
  }
}
