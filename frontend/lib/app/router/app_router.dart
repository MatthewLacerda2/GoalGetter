import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/app/dev/dev_routes.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/app/home/home_shell.dart';
import 'package:goal_getter/app/startup/auth_gate.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/start_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_prompt_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_questions_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/study_plan.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_intro_screen.dart';
import 'package:goal_getter/features/home/presentation/screens/home_screen.dart';
import 'package:goal_getter/features/tutor/presentation/screens/tutor_screen.dart';
import 'package:goal_getter/features/resources/presentation/screens/resources_screen.dart';
import 'package:goal_getter/features/profile/presentation/screens/profile_screen.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:goal_getter/features/lessons/presentation/screens/finish_lesson_screen.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/screens/list_goals_screen.dart';
import 'package:goal_getter/features/goals/presentation/screens/goal_detail_route.dart';

/// The app's go_router configuration.
///
/// `AuthGate` (the `/` splash) resolves auth/onboarding state and redirects via
/// `context.go`. Redirect-based route guards are a documented follow-up (see
/// docs/go_router_migration.md). Rich objects are passed via `extra`
/// (see route_args.dart); paths in [AppRoutes] are the single source of truth.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppConfig.devMenu ? AppRoutes.dev : AppRoutes.splash,
    routes: appRoutes(ref),
  );
});

/// Every route of the app, in one list, so a test walks the table the app
/// itself runs on rather than a copy of it that cannot disagree with it.
List<RouteBase> appRoutes(Ref ref) => [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.start,
        builder: (_, __) => StartScreen(),
      ),
      ..._onboardingRoutes(ref),
      ..._lessonRoutes,
      ..._goalRoutes,
      // Dev-only screen index. Registered only for --dart-define=DEV_MENU=true
      // builds so these paths do not exist in production.
      if (AppConfig.devMenu) ...devRoutes,
      _tabsRoute,
    ];

/// The `extra` a route was handed, when it is there and is what the route asks
/// for.
///
/// `extra` does not survive a web refresh — F5, a pasted URL, a cold load —
/// and the app is distributed through the web first, so that is the ordinary
/// case rather than a corner. Every route that needs one therefore says in its
/// `redirect` where the student goes when it is gone, and its builder only
/// runs with a real one. Falling back to a fixture instead is the defect #139
/// fixed: it showed a real student a fictitious one's questions, plan and
/// results.
T? _extra<T>(GoRouterState state) {
  final extra = state.extra;
  return extra is T ? extra : null;
}

/// The draft the study plan screen shows: the one being navigated with, or the
/// one held across a sign-in detour (`PendingGoalDraft`) — which is in memory,
/// so it is gone after a refresh as well.
GoalDraft? _studyPlanDraft(Ref ref, GoRouterState state) =>
    _extra<GoalDraft>(state) ?? ref.read(pendingGoalDraftProvider);

/// Goal creation: the prompt, the questions Gemini wrote for it, the plan, and
/// the introduction screens `POST /goals` returned.
///
/// None of the three after the prompt can be fetched back after a refresh: the
/// questions and the plan are Gemini's answers to what the student typed a
/// screen earlier, and the introduction screens are generated once, by the
/// creation call, and never stored. So a refresh returns to the step that
/// produces the content again — except on the introduction, where the goal
/// already exists and the first lesson is what came next anyway.
List<RouteBase> _onboardingRoutes(Ref ref) => [
      GoRoute(
        path: AppRoutes.goalPrompt,
        builder: (_, __) => GoalPromptScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalQuestions,
        redirect: (_, state) => _extra<GoalQuestionsArgs>(state) == null
            ? AppRoutes.goalPrompt
            : null,
        builder: (_, state) {
          final args = _extra<GoalQuestionsArgs>(state)!;
          return GoalQuestionsScreen(
            prompt: args.prompt,
            questions: args.questions,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studyPlan,
        redirect: (_, state) =>
            _studyPlanDraft(ref, state) == null ? AppRoutes.goalPrompt : null,
        builder: (_, state) =>
            StudyPlanScreen(draft: _studyPlanDraft(ref, state)!),
      ),
      GoRoute(
        path: AppRoutes.goalIntro,
        redirect: (_, state) => _extra<List<IntroScreenData>>(state) == null
            ? AppRoutes.lesson
            : null,
        builder: (_, state) => GoalIntroScreen(
          screens: _extra<List<IntroScreenData>>(state)!,
        ),
      ),
    ];

/// The lesson and its result. The result is the lesson the student has just
/// answered and the server keeps no "last lesson" to ask for, so a refresh
/// goes home, where those same numbers are part of his own history.
final List<RouteBase> _lessonRoutes = [
  GoRoute(
    path: AppRoutes.lesson,
    builder: (_, __) => LessonScreen(),
  ),
  GoRoute(
    path: AppRoutes.lessonFinish,
    redirect: (_, state) =>
        _extra<FinishLessonArgs>(state) == null ? AppRoutes.home : null,
    builder: (_, state) {
      final args = _extra<FinishLessonArgs>(state)!;
      return FinishLessonScreen(
        title: args.title,
        icon: args.icon,
        timeSpent: args.timeSpent,
        accuracy: args.accuracy,
        elo: args.elo,
      );
    },
  ),
];

/// The goals list and one goal. The detail carries an id in its path, so its
/// `extra` is only a shortcut: without one [GoalDetailRoute] fetches the goal.
final List<RouteBase> _goalRoutes = [
  GoRoute(
    path: AppRoutes.goals,
    builder: (_, __) => const ListGoalsScreen(),
  ),
  GoRoute(
    path: '${AppRoutes.goals}/:id',
    builder: (_, state) => GoalDetailRoute(
      goalId: state.pathParameters['id']!,
      goal: _extra<Goal>(state),
    ),
  ),
];

/// The four bottom-nav tabs, each its own branch so each keeps its own stack.
final RouteBase _tabsRoute = StatefulShellRoute.indexedStack(
  builder: (_, __, navigationShell) =>
      ScaffoldWithNavBar(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const HomeScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.tutor,
          builder: (_, __) => TutorScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.resources,
          builder: (_, __) => const ResourcesScreen(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, __) => ProfileScreen(),
        ),
      ],
    ),
  ],
);
