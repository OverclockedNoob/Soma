import '../models/workout_models.dart';
import 'storage_services.dart';

/// Single source of truth for streak calculations across Home and Statistics.
class StreakService {
  StreakService._();

  static int calculateCurrentStreak({DateTime? now}) {
    return calculateStreak(
      workouts: WorkoutStorage.getAllWorkoutSessions(),
      frozenDates: SettingsStorage.getFrozenDates(),
      activeProgram: ProgramStorage.getActiveProgramModel(),
      now: now,
    );
  }

  static int calculateStreak({
    required List<WorkoutSession> workouts,
    required Iterable<String> frozenDates,
    SplitProgram? activeProgram,
    DateTime? now,
  }) {
    if (workouts.isEmpty) return 0;

    final workoutDays = <DateTime>{};
    DateTime? earliestWorkout;

    for (final session in workouts) {
      final day = session.dayUtc;
      if (day == null) continue;
      workoutDays.add(day);
      if (earliestWorkout == null || day.isBefore(earliestWorkout)) {
        earliestWorkout = day;
      }
    }

    if (workoutDays.isEmpty || earliestWorkout == null) return 0;

    final frozenDays = <DateTime>{};
    for (final raw in frozenDates) {
      final day = tryParseCalendarDayUtc(raw);
      if (day != null) frozenDays.add(day);
    }

    bool isProtectedDay(DateTime dayUtc) {
      if (frozenDays.contains(dayUtc)) return true;
      if (activeProgram != null && activeProgram.isScheduledRestDay(dayUtc)) {
        return true;
      }
      return false;
    }

    DateTime prevDayUtc(DateTime dayUtc) =>
        DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day - 1);

    final ref = now ?? DateTime.now();
    DateTime check = DateTime.utc(ref.year, ref.month, ref.day);

    // Give the user until the end of today before breaking an active streak.
    if (!workoutDays.contains(check) && !isProtectedDay(check)) {
      check = prevDayUtc(check);
    }

    int streak = 0;
    while (!check.isBefore(earliestWorkout)) {
      if (workoutDays.contains(check)) {
        streak++;
        check = prevDayUtc(check);
      } else if (isProtectedDay(check)) {
        check = prevDayUtc(check);
      } else {
        break;
      }
    }

    return streak;
  }
}
