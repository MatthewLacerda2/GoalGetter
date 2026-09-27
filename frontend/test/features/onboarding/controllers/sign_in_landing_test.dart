import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/sign_in_landing.dart';

import '../fake_onboarding_api.dart';
import 'onboarding_container.dart';

void main() {
  test('a held draft brings the sign-in back to the study plan', () async {
    final (c, _) = await onboardingContainer(FakeOnboardingApi());
    c.read(pendingGoalDraftProvider.notifier).hold(draft);

    final landing = await c.read(signInLandingProvider).resolve();

    expect(landing.location, AppRoutes.studyPlan);
    expect(landing.extra, same(draft));
  });

  test('without one, it lands where a launch would', () async {
    final (c, _) = await onboardingContainer(FakeOnboardingApi(), prefs: {});

    final landing = await c.read(signInLandingProvider).resolve();

    expect(landing.location, AppRoutes.start);
    expect(landing.extra, isNull);
  });
}
