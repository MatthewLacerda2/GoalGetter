import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/app/dev/dev_fixtures.dart';
import 'package:goal_getter/app/dev/dev_menu_screen.dart';
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
import 'package:goal_getter/features/lessons/presentation/screens/info_screen.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/screens/list_goals_screen.dart';
import 'package:goal_getter/features/goals/presentation/screens/goals_detail_screen.dart';
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
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.start,
        builder: (_, __) => StartScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalPrompt,
        builder: (_, __) => GoalPromptScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalQuestions,
        builder: (_, state) {
          // `extra` is lost on a web refresh; in dev fall back to fixtures so
          // reloading the page shows the screen instead of a null-cast crash.
          final args = state.extra as GoalQuestionsArgs? ??
              DevFixtures.goalQuestions;
          return GoalQuestionsScreen(
            prompt: args.prompt,
            questions: args.questions,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studyPlan,
        builder: (_, state) {
          // After a web refresh, the draft being committed (if any) still
          // beats the dev fixture.
          final draft = state.extra as GoalDraft? ??
              ref.read(pendingGoalDraftProvider) ??
              DevFixtures.goalDraft;
          return StudyPlanScreen(draft: draft);
        },
      ),
      GoRoute(
        path: AppRoutes.goalIntro,
        builder: (_, state) => GoalIntroScreen(
          screens: state.extra as List<IntroScreenData>? ??
              DevFixtures.introScreens,
        ),
      ),
      GoRoute(
        path: AppRoutes.lesson,
        builder: (_, __) => LessonScreen(),
      ),
      GoRoute(
        path: AppRoutes.lessonFinish,
        builder: (_, state) {
          final args =
              state.extra as FinishLessonArgs? ?? DevFixtures.finishLesson;
          return FinishLessonScreen(
            title: args.title,
            icon: args.icon,
            timeSpent: args.timeSpent,
            accuracy: args.accuracy,
            elo: args.elo,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.goals,
        builder: (_, __) => const ListGoalsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.goals}/:id',
        builder: (_, state) => GoalDetailRoute(
          goalId: state.pathParameters['id']!,
          goal: state.extra as Goal?,
        ),
      ),
      // Dev-only screen index. Registered only for --dart-define=DEV_MENU=true
      // builds so these paths do not exist in production.
      if (AppConfig.devMenu) ...[
        GoRoute(
          path: AppRoutes.dev,
          builder: (_, __) => const DevMenuScreen(),
        ),
        GoRoute(
          path: AppRoutes.devGoalDetail,
          builder: (_, state) => GoalsDetailScreen(
            goal: (state.extra as Goal?) ?? DevFixtures.goalDetail,
          ),
        ),
        GoRoute(
          path: AppRoutes.devInfoScreen,
          builder: (context, __) => InfoScreen(
            icon: Icons.local_fire_department,
            title: 'Nice streak!',
            descriptionText:
                'You have studied 7 days in a row. Keep it up and you will '
                'hit your first milestone this week.',
            buttonText: 'Continue',
            onButtonPressed: () => context.pop(),
          ),
        ),
      ],
      StatefulShellRoute.indexedStack(
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
      ),
    ],
  );
});
