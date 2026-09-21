import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

/// Bypasses the backend call to finalize goal creation (POST /goals), stores a
/// mock active goal id, and routes to the Home screen.
///
/// It no longer fabricates a session: that would overwrite the real one a
/// sign-in stored (#51). Committing the goal for real is the goals
/// integration's job.
Future<void> submitMockFullCreation(
  BuildContext context,
  StudyPlan plan,
) async {
  await SettingsStorage.setCurrentGoalId('mock_goal_id_888');

  if (context.mounted) {
    context.go(AppRoutes.home);
  }
}
