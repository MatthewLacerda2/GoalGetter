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

  testWidgets('create stores the goal, plays the intro, and lands home', (
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
    expect(find.text('Ready?'), findsOneWidget);

    await tester.tap(find.text("Let's start"));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
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
    expect(find.text('Ready?'), findsOneWidget);
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
