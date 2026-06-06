import 'package:flutter/material.dart';
import 'package:goal_getter/app/app.dart';

/// Bypasses Google Sign-In and redirects the user directly to the onboarding flow.
Future<void> handleMockGoogleSignIn(BuildContext context) async {
  // Navigate straight to the onboarding flow
  Navigator.of(context).pushReplacementNamed(AppRoutes.goalPrompt);
}
