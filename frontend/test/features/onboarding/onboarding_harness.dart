import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/core/services/shared_preferences_provider.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/standard_questions_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_prompt_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_questions_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/study_plan.dart';
import 'package:goal_getter/features/onboarding/presentation/sign_in_routing.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_onboarding_api.dart';

const signedIn = {'access_token': 'access', 'refresh_token': 'r1'};

/// The start screen stand-in: a sign-in that has just succeeded.
class _SignedInButton extends ConsumerWidget {
  const _SignedInButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: TextButton(
      onPressed: () => routeAfterSignIn(ref, context),
      child: const Text('START'),
    ),
  );
}

GoRouter _router(String initial, Object? extra) => GoRouter(
  initialLocation: initial,
  initialExtra: extra,
  routes: [
    GoRoute(
      path: AppRoutes.goalPrompt,
      builder: (_, __) => const GoalPromptScreen(),
    ),
    GoRoute(
      path: AppRoutes.goalQuestions,
      builder: (_, s) {
        final args = s.extra! as GoalQuestionsArgs;
        return GoalQuestionsScreen(
          prompt: args.prompt,
          questions: args.questions,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.studyPlan,
      builder: (_, s) => StudyPlanScreen(draft: s.extra! as GoalDraft),
    ),
    GoRoute(
      path: AppRoutes.standardQuestions,
      builder: (_, s) {
        final args = s.extra! as StandardQuestionsArgs;
        return StandardQuestionsScreen(
          goalId: args.goalId,
          questions: args.questions,
        );
      },
    ),
    GoRoute(path: AppRoutes.home, builder: (_, __) => const Text('HOME')),
    GoRoute(path: AppRoutes.lesson, builder: (_, __) => const Text('LESSON')),
    GoRoute(path: AppRoutes.start, builder: (_, __) => const _SignedInButton()),
  ],
);

/// Pumps the goal-creation flow at [initial] on [api], with [prefs] stored.
/// Returns the stored preferences, to read what the flow wrote.
Future<SharedPreferences> pumpFlow(
  WidgetTester tester,
  FakeOnboardingApi api, {
  String initial = AppRoutes.goalPrompt,
  Object? extra,
  Map<String, Object> prefs = signedIn,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final stored = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        onboardingApiProvider.overrideWithValue(api),
        sharedPreferencesProvider.overrideWithValue(stored),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router(initial, extra),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return stored;
}
