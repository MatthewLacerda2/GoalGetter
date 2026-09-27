import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/study_plan_controller.dart';

import '../fake_onboarding_api.dart';
import 'onboarding_container.dart';

void main() {
  final provider = studyPlanControllerProvider(draft);

  test('confirming stores the goal as active and lets the draft go', () async {
    final api = FakeOnboardingApi();
    final (c, prefs) = await onboardingContainer(api);
    c.keep(provider);

    final sent = c.read(provider.notifier).confirm();
    expect(c.read(provider), isA<PlanCommitting>());
    await sent;

    expect(api.lastCreated, same(draft));
    expect(prefs.getString('current_goal_id'), created.id);
    expect((c.read(provider) as PlanCommitted).goal, same(created));
    expect(c.read(pendingGoalDraftProvider), isNull);
  });

  test('without a session, the draft is held for the sign-in', () async {
    final api = FakeOnboardingApi();
    final (c, _) = await onboardingContainer(api, prefs: {});
    c.keep(provider);

    await c.read(provider.notifier).confirm();

    expect(c.read(provider), isA<PlanNeedsSignIn>());
    expect(api.lastCreated, isNull);
    expect(c.read(pendingGoalDraftProvider), same(draft));
  });

  test('a 401 goes to sign in; any other failure is retried here', () async {
    final api = FakeOnboardingApi()
      ..createError = const ApiException(401, 'Session expired');
    final (c, prefs) = await onboardingContainer(api);
    c.keep(provider);
    final controller = c.read(provider.notifier);

    await controller.confirm();
    expect(c.read(provider), isA<PlanNeedsSignIn>());
    expect(c.read(pendingGoalDraftProvider), same(draft));

    api.createError = geminiDown;
    await controller.confirm();
    expect((c.read(provider) as PlanCommitFailed).error, geminiDown);
    expect(prefs.getString('current_goal_id'), isNull);
    expect(c.read(pendingGoalDraftProvider), same(draft));
  });

  test('starting over drops the held draft', () async {
    final (c, _) = await onboardingContainer(FakeOnboardingApi(), prefs: {});
    c.keep(provider);
    await c.read(provider.notifier).confirm();

    c.read(provider.notifier).startOver();
    expect(c.read(pendingGoalDraftProvider), isNull);
  });
}
