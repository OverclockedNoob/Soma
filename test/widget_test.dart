import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:workout_tracker/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkoutApp());

    expect(find.text('Welcome back,'), findsOneWidget);
  });
}
