import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/router/app_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import '../features/fake_backend.dart';

/// A web refresh loses go_router's `extra`, and the four routes that took one
/// fell back to the dev fixtures — in every build (#139). Opening the URL cold
/// is exactly what a refresh does, so each of these starts the real route
/// table at a path with nothing attached.

const _plan = StudyPlan(goalName: 'Learn Italian', description: 'Greetings.');

const _draft =
    GoalDraft(prompt: 'Learn Italian', answers: [], plan: _plan);

const _questions = GoalQuestionsArgs(
  prompt: 'Learn Italian',
  questions: [
    ObjectiveQuestion(
      question: 'How much Italian do you have?',
      options: ['None'],
    ),
  ],
);

/// The real route table, read through a provider so it gets the same `ref` the
/// app's own router gets.
final _routesProvider = Provider<List<RouteBase>>(appRoutes);

/// Where the router ended up.
String _at(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

/// Starts the app's own routes at [path], with [extra] attached (a refresh
/// attaches none) and [held] in the pending-draft provider.
Future<GoRouter> pumpAt(
  WidgetTester tester,
  String path, {
  Object? extra,
  GoalDraft? held,
}) async {
  final backend = FakeBackend({
    'GET /home': [(200, '{"goal_name": "Learn Italian", "current_elo": 1000,'
        ' "current_streak": 0, "recent_lessons": []}')],
    'POST /goals/g1/lessons': [(409, '{"detail": "still preparing"}')],
  });
  await backend.start({'current_goal_id': 'g1'});
  final container = ProviderContainer(overrides: backend.overrides);
  addTearDown(container.dispose);
  if (held != null) {
    container.read(pendingGoalDraftProvider.notifier).hold(held);
  }
  final router = GoRouter(
    initialLocation: path,
    initialExtra: extra,
    routes: container.read(_routesProvider),
  );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('the questions, refreshed, go back to the goal prompt',
      (tester) async {
    final router = await pumpAt(tester, AppRoutes.goalQuestions);

    expect(_at(router), AppRoutes.goalPrompt);
    expect(find.text('How much Italian do you have?'), findsNothing);
  });

  testWidgets('the questions still show when they were passed', (tester) async {
    final router =
        await pumpAt(tester, AppRoutes.goalQuestions, extra: _questions);

    expect(_at(router), AppRoutes.goalQuestions);
    expect(find.text('How much Italian do you have?'), findsOneWidget);
  });

  testWidgets('the study plan, refreshed, goes back to the goal prompt',
      (tester) async {
    final router = await pumpAt(tester, AppRoutes.studyPlan);

    expect(_at(router), AppRoutes.goalPrompt);
  });

  testWidgets('a held draft still beats the missing extra', (tester) async {
    final router = await pumpAt(tester, AppRoutes.studyPlan, held: _draft);

    expect(_at(router), AppRoutes.studyPlan);
    expect(find.text('Learn Italian'), findsOneWidget);
  });

  testWidgets('the introduction, refreshed, goes to the first lesson',
      (tester) async {
    final router = await pumpAt(tester, AppRoutes.goalIntro);

    expect(_at(router), AppRoutes.lesson);
  });

  testWidgets('the lesson result, refreshed, goes home', (tester) async {
    final router = await pumpAt(tester, AppRoutes.lessonFinish);

    expect(_at(router), AppRoutes.home);
  });
}
