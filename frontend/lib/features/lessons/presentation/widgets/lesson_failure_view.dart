import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_state.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The lesson could not open: the bank is still being built (409), there is
/// no active goal, or the call failed (retryable). Never a spinner.
class LessonStartFailureView extends StatelessWidget {
  const LessonStartFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final LessonFailure<LessonStartFailureKind> failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget message = switch (failure.kind) {
      LessonStartFailureKind.notReady => StateMessage(
          icon: Icons.hourglass_top,
          title: l10n.lessonsStillPreparing,
          body: l10n.lessonsStillPreparingBody,
          actionLabel: l10n.lessonCheckAgain,
          onAction: onRetry,
        ),
      LessonStartFailureKind.noActiveGoal => StateMessage(
          icon: Icons.flag_outlined,
          title: l10n.noActiveGoal,
          body: l10n.lessonNoActiveGoalBody,
          actionLabel: l10n.lessonPickGoal,
          onAction: () => context.go(AppRoutes.goals),
        ),
      LessonStartFailureKind.failed => StateMessage(
          icon: Icons.cloud_off,
          isError: true,
          title: l10n.lessonStartFailed,
          body: failure.detail ?? l10n.couldNotReachServer,
          actionLabel: l10n.lessonTryAgain,
          onAction: onRetry,
        ),
    };
    return Column(
      children: [
        Expanded(child: message),
        TextButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l10n.lessonBackHome),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The answers did not reach the server. They stay in the controller's state,
/// so [onRetry] sends the same first attempts again.
class LessonSubmitFailureView extends StatelessWidget {
  const LessonSubmitFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final LessonFailure<void> failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = failure.detail ?? l10n.couldNotReachServer;
    return StateMessage(
      icon: Icons.cloud_upload_outlined,
      isError: true,
      title: l10n.lessonSubmitFailed,
      body: '$detail\n\n${l10n.lessonSubmitFailedBody}',
      actionLabel: l10n.lessonTryAgain,
      onAction: onRetry,
    );
  }
}
