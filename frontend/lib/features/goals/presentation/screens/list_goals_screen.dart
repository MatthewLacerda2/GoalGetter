import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/utils/error_text.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';
import 'package:goal_getter/features/goals/presentation/widgets/goal_card.dart';

/// The student's goals, from `GET /goals`. Each card already shows every field;
/// tapping one opens the detail screen with that same goal (no second fetch).
class ListGoalsScreen extends ConsumerWidget {
  const ListGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final goalsAsync = ref.watch(goalsListControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.goals),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: goalsAsync.when(
        // A retry keeps the old error on screen, so show the spinner instead.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => StateMessage(
          icon: Icons.error_outline,
          isError: true,
          title: l10n.goalsLoadFailed,
          body: errorText(err, l10n),
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(goalsListControllerProvider),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return StateMessage(
              icon: Icons.flag_outlined,
              title: l10n.noGoalsFound,
              actionLabel: l10n.createFirstGoal,
              onAction: () => context.go(AppRoutes.goalPrompt),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(goalsListControllerProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return GoalCard(
                  goal: goal,
                  onTap: () =>
                      context.push(AppRoutes.goalDetail(goal.id), extra: goal),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
