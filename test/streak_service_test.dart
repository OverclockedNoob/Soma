import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/models/workout_models.dart';
import 'package:workout_tracker/services/streak_service.dart';

WorkoutSession _sessionOn(String dateKey) {
  return WorkoutSession(
    id: 'ws-$dateKey',
    name: 'Test Session',
    date: dateKey,
    durationSeconds: 1800,
    durationMinutes: 30,
    calories: 240,
    totalSets: 9,
    totalReps: 90,
    exercises: const <String>['Push-Up'],
    sets: const <CompletedSet>[],
  );
}

void main() {
  group('StreakService', () {
    test('returns 0 when no workouts exist', () {
      final streak = StreakService.calculateStreak(
        workouts: const <WorkoutSession>[],
        frozenDates: const <String>[],
        now: DateTime(2026, 11, 26, 14, 0),
      );
      expect(streak, 0);
    });

    test('counts streaks longer than 30 days without artificial cap', () {
      final today = DateTime.utc(2026, 11, 26);
      final sessions = <WorkoutSession>[
        for (int i = 0; i < 45; i++)
          _sessionOn(formatDateKey(today.subtract(Duration(days: i)))),
      ];

      final streak = StreakService.calculateStreak(
        workouts: sessions,
        frozenDates: const <String>[],
        now: DateTime(2026, 11, 26, 18, 30),
      );
      expect(streak, 45);
    });

    test('keeps streak alive during same-day grace window when yesterday had a workout', () {
      final sessions = <WorkoutSession>[
        _sessionOn('2026-11-25'),
        _sessionOn('2026-11-24'),
        _sessionOn('2026-11-23'),
      ];

      final streak = StreakService.calculateStreak(
        workouts: sessions,
        frozenDates: const <String>[],
        now: DateTime(2026, 11, 26, 9, 0),
      );
      expect(streak, 3);
    });

    test('bridges a missed day with a Recovery Bank freeze without inflating workout count', () {
      final sessions = <WorkoutSession>[
        _sessionOn('2026-11-26'),
        // 2026-11-25 missed, frozen!
        _sessionOn('2026-11-24'),
        _sessionOn('2026-11-23'),
      ];

      final streak = StreakService.calculateStreak(
        workouts: sessions,
        frozenDates: const <String>['2026-11-25'],
        now: DateTime(2026, 11, 26, 20, 0),
      );
      expect(streak, 3);
    });

    test('bridges scheduled rest days inside active split date bounds only', () {
      // 2026-11-26 is Thursday; 2026-11-25 is Wednesday (scheduled Rest Day);
      // 2026-11-24 is Tuesday (workout).
      const program = SplitProgram(
        id: 'split-1',
        name: 'Upper / Lower',
        durationWeeks: 4,
        startDate: '2026-11-01',
        schedule: <String, String?>{
          'Monday': 'w1',
          'Tuesday': 'w2',
          'Wednesday': null, // Rest day
          'Thursday': 'w1',
          'Friday': 'w2',
          'Saturday': null,
          'Sunday': null,
        },
        colorValue: 0xFF8B7CFF,
      );

      final sessions = <WorkoutSession>[
        _sessionOn('2026-11-26'),
        _sessionOn('2026-11-24'),
      ];

      final streakInBounds = StreakService.calculateStreak(
        workouts: sessions,
        frozenDates: const <String>[],
        activeProgram: program,
        now: DateTime(2026, 11, 26, 12, 0),
      );
      expect(streakInBounds, 2);

      // Expired split (1 week starting 2026-10-01) must NOT bridge 2026-11-25.
      final expiredProgram = SplitProgram(
        id: 'split-expired',
        name: 'Old Split',
        durationWeeks: 1,
        startDate: '2026-10-01',
        schedule: program.schedule,
        colorValue: 0xFF8B7CFF,
      );

      final streakExpired = StreakService.calculateStreak(
        workouts: sessions,
        frozenDates: const <String>[],
        activeProgram: expiredProgram,
        now: DateTime(2026, 11, 26, 12, 0),
      );
      expect(streakExpired, 1);
    });

    test('terminates cleanly even if active split has all rest days', () {
      const allRestSplit = SplitProgram(
        id: 'all-rest',
        name: 'All Rest',
        durationWeeks: 52,
        startDate: '2026-01-01',
        schedule: <String, String?>{
          'Monday': null,
          'Tuesday': null,
          'Wednesday': null,
          'Thursday': null,
          'Friday': null,
          'Saturday': null,
          'Sunday': null,
        },
        colorValue: 0xFF8B7CFF,
      );

      final streak = StreakService.calculateStreak(
        workouts: <WorkoutSession>[_sessionOn('2026-11-20')],
        frozenDates: const <String>[],
        activeProgram: allRestSplit,
        now: DateTime(2026, 11, 26, 12, 0),
      );
      expect(streak, 0);
    });
  });
}
