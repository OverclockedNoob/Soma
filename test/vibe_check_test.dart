import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/screens/active_workout_screen.dart';
import 'package:workout_tracker/services/exercise_service.dart';
import 'package:workout_tracker/widgets/vibe_check_sheet.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('soma_vibe_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>('workouts');
    await Hive.openBox<dynamic>('settings');
    await Hive.openBox<dynamic>('custom_workouts');
    await Hive.openBox<dynamic>('programs');
    await ExerciseService.init();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('VibeCheckSheet adapts target reps for low readiness without mutating input', (
    WidgetTester tester,
  ) async {
    final originalExercises = <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'Barbell Bench Press',
        'muscle': 'Chest',
        'sets': 3,
        'targetReps': 10,
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  unawaited(
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => VibeCheckSheet(
                        originalExercises: originalExercises,
                        workoutName: 'Chest Session',
                      ),
                    ),
                  );
                },
                child: const Text('Open Vibe Check'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Vibe Check'));
    await tester.pumpAndSettle();

    expect(find.text('The Vibe Check'), findsOneWidget);

    // Select < 5h sleep + Destroyed soreness -> Take It Easy (0.8x reps -> 8 reps).
    await tester.tap(find.text('< 5h'));
    await tester.pump();
    await tester.tap(find.text('Destroyed'));
    await tester.pump();

    expect(find.text('Take It Easy 😓'), findsOneWidget);

    await tester.tap(find.text('Start Workout'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ActiveWorkoutScreen), findsOneWidget);
    // Caller's original exercise map remains untouched at 10 targetReps.
    expect(originalExercises.first['targetReps'], 10);
  });
}
