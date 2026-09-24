import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';

import '../api_fake.dart';
import 'lesson_json.dart';

void main() {
  testWidgets('shows the first question of the opened lesson', (tester) async {
    final fake = ApiFake({startKey: [(201, lessonJson(2))]});
    await pumpScreen(tester, await fake.overrides(), const LessonScreen());

    expect(find.text('Question 0?'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('a 409 says the lessons are still being prepared',
      (tester) async {
    final fake = ApiFake({
      startKey: [(409, '{"detail": "Lessons are still being prepared"}')],
    });
    await pumpScreen(tester, await fake.overrides(), const LessonScreen());

    expect(find.text('Your lessons are still being prepared'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a failed submit is shown with a retry', (tester) async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(1))],
      answersKey: [(500, '{"detail": "boom"}')],
    });
    await pumpScreen(tester, await fake.overrides(), const LessonScreen());
    await tester.tap(find.text('a'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton)); // Enter
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton)); // Continue: submits
    await tester.pumpAndSettle();

    expect(find.text('Your answers were not saved'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
