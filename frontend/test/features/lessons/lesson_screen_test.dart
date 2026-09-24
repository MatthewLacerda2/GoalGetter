import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';

import '../api_fake.dart';
import 'lesson_json.dart';

/// The one button at the foot of the lesson screen: "Enter", then "Continue".
ElevatedButton enterButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton));

/// The answers of the last submit.
List<dynamic> answersSent(ApiFake fake) {
  final body = fake.requests.lastWhere((r) => r.$1 == answersKey).$2;
  return (jsonDecode(body) as Map<String, dynamic>)['answers'] as List;
}

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

  testWidgets('a lesson of eight cannot be submitted with one unanswered',
      (tester) async {
    // The button is dead until a choice is picked, so the screen offers no way
    // past a question: the submit only happens after the eighth answer (#86).
    final fake = ApiFake({
      startKey: [(201, lessonJson(8))],
      answersKey: [(200, evaluationJson)],
      'GET /home': [(404, '{"detail": "No active goal"}')],
    });
    await pumpScreen(tester, await fake.overrides(), const LessonScreen());

    for (var i = 0; i < 8; i++) {
      expect(find.text('${i + 1} / 8'), findsOneWidget);
      expect(enterButton(tester).onPressed, isNull, reason: 'question ${i + 1}');
      expect(fake.count(answersKey), 0, reason: 'question ${i + 1}');
      await tester.tap(find.text('a'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton)); // Enter
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton)); // Continue
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(fake.count(answersKey), 1);
    expect(answersSent(fake), hasLength(8));
  });

  // The answers are still on screen, so the failure is said over them (#98).
  testWidgets('a failed submit is a snackbar with a retry', (tester) async {
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

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Your answers were not saved'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Question 0?'), findsOneWidget);
  });
}
