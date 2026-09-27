import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/features/lessons/presentation/screens/info_screen.dart';

import 'golden_harness.dart';

/// A lesson walked through as the student walks it: a question with a choice
/// picked, the review intro after a miss (the app's [InfoScreen]), and the
/// finish screen with the lesson's result.

/// Picks [choice], then "Enter" and "Continue".
Future<void> _answer(WidgetTester tester, String choice) async {
  await tester.tap(find.text(choice));
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton)); // Enter
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton)); // Continue
  await tester.pumpAndSettle();
}

/// The lesson, its first question answered right and its second missed.
Future<void> _toReview(WidgetTester tester, Look look) async {
  await openAt(tester, look, AppRoutes.lesson);
  await _answer(tester, 'Knight');
  await _answer(tester, 'c1');
  await _answer(tester, '1');
}

void main() {
  goldenTest('lesson', (tester, look) async {
    await openAt(tester, look, AppRoutes.lesson);
    await tester.tap(find.text('Knight'));
    await tester.pumpAndSettle();
  });

  goldenTest('review_intro', _toReview);

  goldenTest('finish_lesson', (tester, look) async {
    await _toReview(tester, look);
    await tester.tap(find.descendant(
      of: find.byType(InfoScreen),
      matching: find.byType(ElevatedButton),
    ));
    await tester.pumpAndSettle();
    await _answer(tester, 'g1');
  });
}
