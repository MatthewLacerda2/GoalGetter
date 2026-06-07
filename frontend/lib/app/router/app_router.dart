import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openapi/api.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/app/home/home_shell.dart';
import 'package:goal_getter/app/startup/auth_gate.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/start_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_prompt_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_questions_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/study_plan.dart';
import 'package:goal_getter/features/home/presentation/screens/home_screen.dart';
import 'package:goal_getter/features/tutor/presentation/screens/tutor_screen.dart';
import 'package:goal_getter/features/resources/presentation/screens/resources_screen.dart';
import 'package:goal_getter/features/profile/presentation/screens/profile_screen.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:goal_getter/features/lessons/presentation/screens/finish_lesson_screen.dart';
import 'package:goal_getter/features/goals/presentation/screens/list_goals_screen.dart';
import 'package:goal_getter/features/goals/presentation/screens/goals_detail_screen.dart';

/// The app's go_router configuration.
///
/// `AuthGate` (the `/` splash) resolves auth/onboarding state and redirects via
/// `context.go`. Redirect-based route guards are a documented follow-up (see
/// docs/go_router_migration.md). Rich objects are passed via `extra`
/// (see route_args.dart); paths in [AppRoutes] are the single source of truth.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
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
          final args = state.extra as GoalQuestionsArgs;
          return GoalQuestionsScreen(
            prompt: args.prompt,
            questions: args.questions,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.studyPlan,
        builder: (_, state) {
          final plan = state.extra as GoalStudyPlanResponse;
          return StudyPlanScreen(plan: plan);
        },
      ),
      GoRoute(
        path: AppRoutes.lesson,
        builder: (_, __) => LessonScreen(),
      ),
      GoRoute(
        path: AppRoutes.lessonFinish,
        builder: (_, state) {
          final args = state.extra as FinishLessonArgs;
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
        builder: (_, state) {
          final goal = state.extra as GoalListItem;
          return GoalsDetailScreen(goal: goal);
        },
      ),
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
