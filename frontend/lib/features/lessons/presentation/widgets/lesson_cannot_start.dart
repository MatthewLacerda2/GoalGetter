import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_controller.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The lesson could not open: the question bank is still being built (409),
/// there is no active goal, or the call failed and can be tried again. The
/// first two are states, not failures; only the third is a [FailureView].
///
/// [reason] is [LessonNotReady], [LessonNoActiveGoal], or whatever opening the
/// lesson threw. Trying again opens a new one.
class LessonCannotStart extends ConsumerWidget {
  const LessonCannotStart(this.reason, {super.key});

  final Object reason;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void retry() => ref.invalidate(lessonControllerProvider);
    final Widget message = switch (reason) {
      LessonNotReady() => StateMessage(
        icon: Icons.hourglass_top,
        title: l10n.lessonsStillPreparing,
        body: l10n.lessonsStillPreparingBody,
        actionLabel: l10n.checkAgain,
        onAction: retry,
      ),
      LessonNoActiveGoal() => StateMessage(
        icon: Icons.flag_outlined,
        title: l10n.noActiveGoal,
        body: l10n.lessonNoActiveGoalBody,
        actionLabel: l10n.lessonPickGoal,
        onAction: () => context.go(AppRoutes.goals),
      ),
      _ => FailureView(
        error: reason,
        title: l10n.lessonStartFailed,
        onRetry: retry,
      ),
    };
    return Column(
      children: [
        Expanded(child: message),
        TextButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l10n.lessonBackHome),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}
