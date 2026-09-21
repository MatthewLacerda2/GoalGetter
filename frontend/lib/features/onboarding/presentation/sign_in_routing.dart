import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/startup/app_start_controller.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';

/// Where a fresh sign-in lands: back on the study plan when the student was
/// committing a goal (the draft is held), else wherever a launch would go.
Future<void> routeAfterSignIn(WidgetRef ref, BuildContext context) async {
  final draft = ref.read(pendingGoalDraftProvider);
  if (draft != null) {
    context.go(AppRoutes.studyPlan, extra: draft);
    return;
  }
  final result = await ref.read(appStartControllerProvider).evaluate();
  if (context.mounted) context.go(result.destination.location);
}
