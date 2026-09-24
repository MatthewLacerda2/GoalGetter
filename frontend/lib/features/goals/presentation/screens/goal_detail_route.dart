import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';
import 'package:goal_getter/features/goals/presentation/screens/goals_detail_screen.dart';

/// `/goals/:id`. The list hands the goal over through `extra`; a deep link or a
/// web refresh loses `extra`, so the goal is then looked up in `GET /goals`
/// (the same list, not a per-goal fetch, which does not exist).
class GoalDetailRoute extends ConsumerWidget {
  const GoalDetailRoute({super.key, required this.goalId, this.goal});

  final String goalId;
  final Goal? goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handedOver = goal;
    if (handedOver != null) return GoalsDetailScreen(goal: handedOver);

    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(goalsListControllerProvider);
    Widget message(Widget child) => Scaffold(appBar: AppBar(), body: child);

    return goalsAsync.when(
      skipLoadingOnRefresh: false,
      loading: () =>
          message(const Center(child: CircularProgressIndicator())),
      error: (err, _) => message(FailureView(
        error: err,
        title: l10n.goalsLoadFailed,
        onRetry: () => ref.invalidate(goalsListControllerProvider),
      )),
      data: (goals) {
        for (final candidate in goals) {
          if (candidate.id == goalId) {
            return GoalsDetailScreen(goal: candidate);
          }
        }
        return message(StateMessage(
          icon: Icons.search_off,
          title: l10n.goalNotFound,
          actionLabel: l10n.backToGoals,
          onAction: () => context.go(AppRoutes.goals),
        ));
      },
    );
  }
}
