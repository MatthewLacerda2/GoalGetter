import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/dev/dev_fixtures.dart';
import 'package:goal_getter/app/dev/dev_menu_screen.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/screens/goals_detail_screen.dart';
import 'package:goal_getter/features/lessons/presentation/screens/info_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_questions_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/standard_questions_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/study_plan.dart';

/// The routes that exist only in a `--dart-define=DEV_MENU=true` build.
///
/// They live here, beside the fixtures they show, because this is the one
/// directory allowed to name [DevFixtures]: invented content reaching a real
/// student is the defect #139 fixed, and `tool/frontend_linter.dart` now
/// refuses a fixture named anywhere else. `app_router.dart` spreads this list
/// behind `if (AppConfig.devMenu)`, so none of these paths exist in a
/// production build.
final List<RouteBase> devRoutes = [
  GoRoute(
    path: AppRoutes.dev,
    builder: (_, __) => const DevMenuScreen(),
  ),
  GoRoute(
    path: AppRoutes.devGoalQuestions,
    builder: (_, __) => GoalQuestionsScreen(
      prompt: DevFixtures.goalQuestions.prompt,
      questions: DevFixtures.goalQuestions.questions,
    ),
  ),
  GoRoute(
    path: AppRoutes.devStudyPlan,
    builder: (_, __) => StudyPlanScreen(draft: DevFixtures.goalDraft),
  ),
  GoRoute(
    path: AppRoutes.devStandardQuestions,
    builder: (_, __) => StandardQuestionsScreen(
      goalId: DevFixtures.standardQuestions.goalId,
      questions: DevFixtures.standardQuestions.questions,
    ),
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
];
