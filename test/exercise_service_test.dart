import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/data/exercise_data.dart';
import 'package:workout_tracker/models/workout_models.dart';
import 'package:workout_tracker/services/exercise_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    ExerciseService.resetForTesting();
    await ExerciseService.init();
  });

  group('ExerciseService (100% local 500-exercise catalog)', () {
    test('loads all 500 bundled exercises offline with unique display names', () {
      final all = ExerciseService.allItems;
      expect(all.length, 500);
      expect(ExerciseData.items.length, 500);

      final uniqueNames = all
          .map((ExerciseItem e) => e.name.toLowerCase())
          .toSet();
      expect(
        uniqueNames.length,
        500,
        reason: 'Duplicate raw JSON names must be disambiguated deterministically',
      );
    });

    test('parses real difficulty tiers and secondary muscles from JSON', () {
      final all = ExerciseService.allItems;
      final difficulties = all.map((ExerciseItem e) => e.difficulty).toSet();

      expect(
        difficulties,
        containsAll(<String>['Beginner', 'Intermediate', 'Advanced']),
      );
      expect(all.any((ExerciseItem e) => e.secondaryMuscles.isNotEmpty), isTrue);
    });

    test('Gym Tetris findSubstitute returns same-muscle local exercise matching requested equipment', () {
      final chestBarbell = ExerciseService.allItems.firstWhere(
        (ExerciseItem e) =>
            e.muscle == 'Chest' && e.equipment.toLowerCase().contains('barbell'),
      );

      final currentRoutine = chestBarbell.toRoutineExercise(
        sets: 4,
        targetReps: 8,
      );

      final substituted = ExerciseService.findSubstitute(
        current: currentRoutine,
        equipmentChoice: 'Dumbbells',
        excludedNames: <String>{chestBarbell.name},
      );

      expect(substituted.muscle, 'Chest');
      expect(substituted.sets, 4);
      expect(substituted.targetReps, 8);
      expect(
        substituted.name.toLowerCase(),
        isNot(chestBarbell.name.toLowerCase()),
      );
      expect(
        (substituted.equipment ?? '').toLowerCase(),
        anyOf(contains('dumbbell'), contains('kettlebell')),
      );
    });
  });
}
