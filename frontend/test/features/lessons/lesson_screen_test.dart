import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:goal_getter/features/lessons/presentation/screens/info_screen.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import '../../contract/error_body.dart';
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

/// Taps choice [label], then "Enter", then "Continue!".
Future<void> answer(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton)); // Enter
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton)); // Continue
  await tester.pumpAndSettle();
}

/// The lesson inside a router, whose finish route shows the elo it was handed.
Future<void> pumpRouted(WidgetTester tester, List<Override> overrides) async {
  final router = GoRouter(
    initialLocation: AppRoutes.lesson,
    routes: [
      GoRoute(path: AppRoutes.lesson, builder: (_, __) => const LessonScreen()),
      GoRoute(
        path: AppRoutes.lessonFinish,
        builder: (_, state) =>
            Text('finished ${(state.extra! as LessonEvaluation).elo}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    retry: noAutomaticRetry,
    overrides: overrides,
    child: MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the first question of the opened lesson', (tester) async {
    final fake = ApiFake({startKey: [(201, lessonJson(2))]});
    await pumpScreen(tester, await fake.overrides(), const LessonScreen());

    expect(find.text('Question 0?'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  // Where the student lands at the end of onboarding (#131): a bank that is
  // still being generated must read as a wait with a retry (#98), on the
  // lesson screen, and never send him anywhere.
  testWidgets('a 409 says the lessons are still being prepared',
      (tester) async {
    final fake = ApiFake({
      startKey: [(409, errorBody(ErrorCode.lessonsNotReady))],
    });
    await pumpScreen(tester, await fake.overrides(), const LessonScreen());

    expect(find.text('Your lessons are still being prepared'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a lesson of eight cannot be submitted with one unanswered',
      (tester) async {
    // The button is dead until a choice is picked, so the screen offers no way
    // past a question: the submit only happens after the eighth answer (#86).
    final fake = ApiFake({
      startKey: [(201, lessonJson(8))],
      answersKey: [(200, evaluationJson)],
      'GET /home': [(404, errorBody(ErrorCode.noActiveGoal))],
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
      answersKey: [(500, crashed)],
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
    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Question 0?'), findsOneWidget);
  });

  testWidgets('a missed question comes back after the review intro, then the '
      'finish screen', (tester) async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(2))],
      answersKey: [(200, evaluationJson)],
      'GET /home': [(404, errorBody(ErrorCode.noActiveGoal))],
    });
    await pumpRouted(tester, await fake.overrides());

    await answer(tester, 'a'); // right
    await answer(tester, 'a'); // wrong: question 1's answer is 'b'
    expect(find.text("Now let's correct your mistakes"), findsOneWidget);
    expect(tester.getTopLeft(find.byType(InfoScreen)).dx, 0);

    // The intro's own button; the answered question lies under it.
    await tester.tap(find.descendant(
      of: find.byType(InfoScreen),
      matching: find.text('Continue!'),
    ));
    // It slides back out to the right, as the page it used to be popped.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(tester.getTopLeft(find.byType(InfoScreen)).dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.text("Now let's correct your mistakes"), findsNothing);
    expect(find.text('Question 1?'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);

    await answer(tester, 'b');
    expect(find.text('finished 12'), findsOneWidget);
    expect(fake.count(answersKey), 1);
  });

  testWidgets('a failed start offers a retry that opens a new lesson',
      (tester) async {
    final fake = ApiFake({
      startKey: [(500, crashed), (201, lessonJson(1))],
    });
    await pumpScreen(tester, await fake.overrides(), const LessonScreen());
    expect(find.textContaining('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Question 0?'), findsOneWidget);
  });
}
