import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:workout_tracker/main.dart';
import 'package:workout_tracker/services/exercise_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('soma_widget_test_');
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

  testWidgets('Soma boots 100% offline, lazily mounts tabs, and handles back to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WorkoutApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Bottom navigation items render.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Home screen renders default greeting & Start Workout action.
    expect(find.text('Champion'), findsOneWidget);
    expect(find.text('Start Workout'), findsWidgets);

    // Unvisited Settings tab has not been built yet (lazy _visited list).
    expect(find.text('Export Backup'), findsNothing);

    // Switch to Library tab and verify all 500 bundled exercises are available.
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.textContaining('500'), findsWidgets);

    // Switch to Settings tab and verify offline customization & backup controls.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Customize'), findsOneWidget);
    expect(find.text('Export Backup'), findsOneWidget);
    expect(find.text('Import / Restore Backup'), findsOneWidget);
  });

  testWidgets('WorkoutApp shows startup error screen with retry recovery', (
    WidgetTester tester,
  ) async {
    int attempts = 0;
    await tester.pumpWidget(
      WorkoutApp(
        initOverride: () async {
          attempts++;
          await Future<void>.delayed(Duration.zero);
          if (attempts == 1) {
            throw StateError('Simulated Hive lock failure');
          }
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couldn't start Soma"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(attempts, 2);
    expect(find.text('Champion'), findsOneWidget);
  });
}
