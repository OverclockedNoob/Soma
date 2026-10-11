import 'storage_services.dart';

// Single source of truth for streak calculation.
//
// This used to live in two places (HomeScreen and StatisticsScreen) with
// subtly different rules — Home knew about scheduled rest days, Stats only
// knew about coin freezes, and Stats had a gap-bridging bug that dropped
// workout days after a freeze and counted frozen days *into* the streak
// number. Both screens now call this service so the number can't drift.
//
// The rules (matching what the README promises):
//   • A day keeps the streak alive if the user worked out, froze it with a
//     Recovery Coin, or it was a scheduled rest day in their active program.
//   • Only actual workout days increment the streak number — freezes and
//     rest days just prevent it from breaking.
//   • If today isn't "alive" yet (no workout, no freeze, not a rest day),
//     the streak is counted starting from yesterday, so it doesn't reset
//     at midnight before you've had a chance to train.
class StreakService {
  StreakService._();

  static const List<String> fullDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  /// How far back scheduled rest days are derived from the active program.
  /// Going further doesn't matter — a real gap would've already killed the
  /// streak long before this window, and it bounds the walk-back loop.
  static const int restDayLookbackDays = 30;

  /// Absolute cap on the walk-back loop, purely a safety net so a pathological
  /// dataset (everything frozen/rest forever) can't spin forever.
  static const int _maxLookbackDays = 3650;

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Canonical "yyyy-MM-dd" key — the format used for frozen dates in
  /// settings storage and workout `date` fields everywhere in the app.
  static String dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// The active program is the last saved one — same assumption HomeScreen
  /// has always made (there's no explicit isActive flag yet).
  static Map<String, dynamic>? getActiveProgram() {
    try {
      final programs = ProgramStorage.getAllPrograms();
      return programs.isEmpty ? null : programs.last;
    } catch (_) {
      return null; // storage hiccup — treat as "no program", never crash
    }
  }

  /// Days within the lookback window that the program's schedule leaves
  /// unassigned — i.e. intentional rest days that shouldn't break a streak.
  static Set<DateTime> restDaysFor(Map<String, dynamic>? program, {DateTime? now}) {
    final rest = <DateTime>{};
    if (program == null || program['schedule'] == null) return rest;
    try {
      final schedule = Map<String, dynamic>.from(program['schedule'] as Map);
      final today = _normalize(now ?? DateTime.now());
      for (int i = 0; i < restDayLookbackDays; i++) {
        final d = today.subtract(Duration(days: i));
        final dayName = fullDays[d.weekday - 1];
        if (schedule[dayName] == null) rest.add(d);
      }
    } catch (_) {
      // malformed schedule — safest fallback is "no rest days"
    }
    return rest;
  }

  /// Pure calculation, no storage access — pass in whatever day sets you
  /// already have. Handy for tests and for screens that loaded the data
  /// themselves.
  static int calculateStreak({
    required Iterable<DateTime> workoutDays,
    Iterable<DateTime> frozenDays = const [],
    Iterable<DateTime> restDays = const [],
    DateTime? now,
  }) {
    final workouts = workoutDays.map(_normalize).toSet();
    if (workouts.isEmpty) return 0;

    final frozen = frozenDays.map(_normalize).toSet();
    final rest = restDays.map(_normalize).toSet();

    bool isAlive(DateTime d) =>
        workouts.contains(d) || frozen.contains(d) || rest.contains(d);

    final today = _normalize(now ?? DateTime.now());
    var check = isAlive(today) ? today : today.subtract(const Duration(days: 1));

    int streak = 0;
    int guard = 0;
    while (isAlive(check) && guard < _maxLookbackDays) {
      if (workouts.contains(check)) streak++;
      check = check.subtract(const Duration(days: 1));
      guard++;
    }
    return streak;
  }

  /// Convenience wrapper: pulls workouts, frozen dates and the active
  /// program straight from local storage. Never throws — worst case it
  /// reports 0, same as the old screen-level implementations.
  static int currentStreak() {
    try {
      final workoutDays = <DateTime>[];
      for (final w in WorkoutStorage.getAllWorkouts()) {
        final raw = w['date'];
        if (raw is String) {
          final d = DateTime.tryParse(raw);
          if (d != null) workoutDays.add(d);
        }
      }

      final frozenDays = <DateTime>[];
      for (final s in SettingsStorage.getFrozenDates()) {
        final d = DateTime.tryParse(s);
        if (d != null) frozenDays.add(d);
      }

      return calculateStreak(
        workoutDays: workoutDays,
        frozenDays: frozenDays,
        restDays: restDaysFor(getActiveProgram()),
      );
    } catch (_) {
      return 0;
    }
  }
}
