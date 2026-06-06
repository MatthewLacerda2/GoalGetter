import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

/// Bypasses the backend call to finalize goal creation,
/// stores dummy credentials in local storage, and routes to Home screen.
Future<void> submitMockFullCreation(
  BuildContext context,
  GoalStudyPlanResponse plan,
) async {
  final authService = AuthService();

  // Store mock JWT access token and student credentials
  await authService.storeFinalCredentials(
    "mock_access_token_jwt_123456",
    {
      'id': 'mock_student_id_999',
      'email': 'mockuser@example.com',
      'name': 'Mock GoalGetter Student',
      'google_id': 'mock_google_id_777',
    },
  );

  // Store a mock active goal ID to satisfy storage checks
  await SettingsStorage.setCurrentGoalId("mock_goal_id_888");

  if (Navigator.of(context).mounted) {
    // Navigate straight into the app dashboard.
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
      arguments: HomeRouteArgs(selectedIndex: 0),
    );
  }
}
