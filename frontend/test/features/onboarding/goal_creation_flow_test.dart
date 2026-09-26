import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/study_plan.dart';

import 'fake_onboarding_api.dart';
import 'onboarding_harness.dart';

const _questions = GoalQuestionsArgs(
  prompt: 'Learn Italian',
  questions: [question],
);

Future<void> answer(WidgetTester tester) async {
  await tester.tap(find.text('A few words'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the answers go to the study plan', (tester) async {
    final api = FakeOnboardingApi();
    await pumpFlow(
      tester,
      api,
      initial: AppRoutes.goalQuestions,
      extra: _questions,
    );
    await answer(tester);
    expect(find.text(plan.goalName), findsOneWidget);
    expect(api.lastAnswers!.single.question, question.question);
    expect(api.lastAnswers!.single.answer, 'A few words');
  });

  // #174: from the question taking the screen to the tap that answers it.
  testWidgets('each answer carries the seconds it took', (tester) async {
    final api = FakeOnboardingApi();
    await pumpFlow(
      tester,
      api,
      initial: AppRoutes.goalQuestions,
      extra: _questions,
    );
    await tester.pump(const Duration(seconds: 5));
    await answer(tester);
    expect(api.lastAnswers!.single.totalSeconds, 5);
  });

  testWidgets('a failed study plan keeps the answers for the retry', (
    tester,
  ) async {
    final api = FakeOnboardingApi()..planError = geminiDown;
    await pumpFlow(
      tester,
      api,
      initial: AppRoutes.goalQuestions,
      extra: _questions,
    );
    await answer(tester);
    expect(find.text(geminiDown.detail), findsOneWidget);

    api.planError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text(plan.goalName), findsOneWidget);
    expect(api.lastAnswers!.single.answer, 'A few words');
  });

  // #131: the end of onboarding is the first lesson, not the dashboard. #132:
  // the wait in between is the standard questions, never a spinner and never
  // an introduction screen. What happens when the bank is not ready yet is the
  // lesson screen's own 409 message with a retry (lesson_screen_test.dart),
  // never a bounce to home.
  testWidgets('create stores the goal and asks what we already know to ask', (
    tester,
  ) async {
    final api = FakeOnboardingApi();
    final prefs = await pumpFlow(
      tester,
      api,
      initial: AppRoutes.studyPlan,
      extra: draft,
    );
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    expect(prefs.getString('current_goal_id'), created.id);
    expect(find.text('How old are you?'), findsOneWidget);
    expect(find.text('18 to 24'), findsOneWidget);
  });

  testWidgets('answering them all sends them and starts the lesson', (
    tester,
  ) async {
    final api = FakeOnboardingApi();
    await pumpFlow(tester, api, initial: AppRoutes.studyPlan, extra: draft);
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('18 to 24'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My work or my career'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON'), findsOneWidget);
    expect(api.lastAnsweredGoalId, created.id);
    expect(
      api.lastStandardAnswers!.map((a) => '${a.questionKey}=${a.optionKey}'),
      ['age=18to24', 'purpose=work'],
    );
  });

  testWidgets('each standard answer carries the seconds it took', (
    tester,
  ) async {
    final api = FakeOnboardingApi();
    await pumpFlow(tester, api, initial: AppRoutes.studyPlan, extra: draft);
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('18 to 24'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9));
    await tester.tap(find.text('My work or my career'));
    await tester.pumpAndSettle();

    expect(api.lastStandardAnswers!.map((a) => a.totalSeconds), [4, 9]);
  });

  testWidgets('skipping them goes to the lesson and sends nothing', (
    tester,
  ) async {
    final api = FakeOnboardingApi();
    await pumpFlow(tester, api, initial: AppRoutes.studyPlan, extra: draft);
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('LESSON'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    expect(api.lastStandardAnswers, isNull);
  });

  testWidgets('a failed create keeps the plan and retries it', (tester) async {
    final api = FakeOnboardingApi()..createError = geminiDown;
    await pumpFlow(tester, api, initial: AppRoutes.studyPlan, extra: draft);
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    expect(find.text(geminiDown.detail), findsOneWidget);
    expect(find.text(plan.goalName), findsOneWidget);

    api.createError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('How old are you?'), findsOneWidget);
  });

  testWidgets('without a session, sign-in comes back to the same draft', (
    tester,
  ) async {
    final api = FakeOnboardingApi();
    await pumpFlow(
      tester,
      api,
      initial: AppRoutes.studyPlan,
      extra: draft,
      prefs: {},
    );
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();
    expect(api.lastCreated, isNull);
    final container = ProviderScope.containerOf(
      tester.element(find.text('START')),
    );
    expect(container.read(pendingGoalDraftProvider), same(draft));

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();
    final screen = tester.widget<StudyPlanScreen>(find.byType(StudyPlanScreen));
    expect(screen.draft, same(draft));
  });
}
