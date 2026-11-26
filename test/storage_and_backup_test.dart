import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/core/event_bus.dart';
import 'package:workout_tracker/models/workout_models.dart';
import 'package:workout_tracker/services/backup_service.dart';
import 'package:workout_tracker/services/storage_services.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('soma_storage_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>('workouts');
    await Hive.openBox<dynamic>('settings');
    await Hive.openBox<dynamic>('custom_workouts');
    await Hive.openBox<dynamic>('programs');
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('CustomWorkoutStorage updates routines in-place and cleans split references on delete', () async {
    const routineV1 = WorkoutRoutine(
      id: 'routine-1',
      name: 'Push Day',
      description: 'Initial',
      exercises: <RoutineExercise>[
        RoutineExercise(name: 'Push-Up', muscle: 'Chest', sets: 3, targetReps: 12),
      ],
      createdAt: '2026-11-26T00:00:00.000Z',
    );
    await CustomWorkoutStorage.saveRoutine(routineV1);
    expect(CustomWorkoutStorage.getAllRoutines().length, 1);

    // Edit same routine ID -> must update in-place without duplicating!
    const routineV2 = WorkoutRoutine(
      id: 'routine-1',
      name: 'Heavy Push Day',
      description: 'Updated',
      exercises: <RoutineExercise>[
        RoutineExercise(name: 'Bench Press', muscle: 'Chest', sets: 4, targetReps: 8),
      ],
      createdAt: '2026-11-26T00:00:00.000Z',
    );
    await CustomWorkoutStorage.saveRoutine(routineV2);

    final routines = CustomWorkoutStorage.getAllRoutines();
    expect(routines.length, 1);
    expect(routines.first.name, 'Heavy Push Day');
    expect(routines.first.exercises.first.sets, 4);

    // Create a split referencing routine-1, then delete routine-1.
    const split = SplitProgram(
      id: 'split-1',
      name: 'PPL',
      durationWeeks: 4,
      startDate: '2026-11-26',
      schedule: <String, String?>{
        'Monday': 'routine-1',
        'Tuesday': null,
      },
      colorValue: 0xFF8B7CFF,
    );
    await ProgramStorage.saveProgramModel(split);

    await CustomWorkoutStorage.deleteCustomWorkout('routine-1');
    expect(CustomWorkoutStorage.getAllRoutines(), isEmpty);

    final updatedSplit = ProgramStorage.getActiveProgramModel();
    expect(updatedSplit, isNotNull);
    expect(updatedSplit!.schedule['Monday'], isNull);
  });

  test('ProgramStorage persists active split selection across reads', () async {
    const splitA = SplitProgram(
      id: 'split-a',
      name: 'Split A',
      durationWeeks: 4,
      startDate: '2026-11-01',
      schedule: <String, String?>{'Monday': 'r1'},
      colorValue: 0xFF8B7CFF,
    );
    const splitB = SplitProgram(
      id: 'split-b',
      name: 'Split B',
      durationWeeks: 6,
      startDate: '2026-11-15',
      schedule: <String, String?>{'Tuesday': 'r1'},
      colorValue: 0xFF3DDCB8,
    );

    await ProgramStorage.saveProgramModel(splitA, makeActive: true);
    await ProgramStorage.saveProgramModel(splitB, makeActive: false);
    expect(ProgramStorage.getActiveProgramModel()?.id, 'split-a');

    await ProgramStorage.setActiveProgram('split-b');
    expect(ProgramStorage.getActiveProgramModel()?.id, 'split-b');
  });

  test('BackupService exports and restores full state round-trip and notifies WorkoutEventBus', () async {
    await SettingsStorage.setUserName('Aarav');
    await SettingsStorage.setUserTitle('Powerlifter');
    await SettingsStorage.setWeight(78);
    await SettingsStorage.setAge(27);
    await SettingsStorage.setRecoveryCoins(3);
    final froze = await SettingsStorage.spendCoinAndFreezeDate('2026-11-25');
    expect(froze, isTrue);

    await WorkoutStorage.saveWorkoutSession(
      const WorkoutSession(
        id: 'session-1',
        name: 'Morning Lift',
        date: '2026-11-26',
        durationSeconds: 2400,
        durationMinutes: 40,
        calories: 320,
        totalSets: 2,
        totalReps: 16,
        exercises: <String>['Barbell Squat'],
        sets: <CompletedSet>[
          CompletedSet(
            exerciseIndex: 0,
            exercise: 'Barbell Squat',
            setNumber: 1,
            reps: 8,
          ),
          CompletedSet(
            exerciseIndex: 0,
            exercise: 'Barbell Squat',
            setNumber: 2,
            reps: 8,
          ),
        ],
      ),
    );

    final jsonPayload = BackupService.createBackupJson();

    // Wipe state completely before restoring.
    await WorkoutStorage.clearAll();
    await SettingsStorage.setUserName('Reset');
    expect(WorkoutStorage.getAllWorkoutSessions(), isEmpty);

    final beforeRevision = WorkoutEventBus.instance.revision.value;
    final summary = await BackupService.restoreFromJson(jsonPayload);

    expect(WorkoutEventBus.instance.revision.value, greaterThan(beforeRevision));
    expect(summary.workoutsRestored, 1);
    expect(SettingsStorage.getUserName(), 'Aarav');
    expect(SettingsStorage.getUserTitle(), 'Powerlifter');
    expect(SettingsStorage.getWeight(), 78);
    expect(SettingsStorage.getAge(), 27);
    expect(SettingsStorage.getRecoveryCoins(), 2);
    expect(SettingsStorage.getFrozenDates(), contains('2026-11-25'));
    expect(WorkoutStorage.getAllWorkoutSessions().single.totalReps, 16);

    // Rejects malformed JSON cleanly without corrupting restored data.
    await expectLater(
      BackupService.restoreFromJson('{"not_a_valid_backup": true}'),
      throwsFormatException,
    );
    expect(SettingsStorage.getUserName(), 'Aarav');
  });
}
