import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';

/// Bypasses Google Sign-In and redirects the user directly to the onboarding flow.
Future<void> handleMockGoogleSignIn(BuildContext context) async {
  // Navigate straight to the onboarding flow
  context.go(AppRoutes.goalPrompt);
}
