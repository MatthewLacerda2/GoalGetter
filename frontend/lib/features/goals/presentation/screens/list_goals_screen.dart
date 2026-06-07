import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/error_retry_widget.dart';
import 'package:goal_getter/features/goals/presentation/screens/goals_detail_screen.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';

class ListGoalsScreen extends ConsumerWidget {
  const ListGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsListControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.goals),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: goalsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: (err, stack) => ErrorRetryWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.read(goalsListControllerProvider.notifier).refresh(),
        ),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noGoalsFound,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await context.push<GoalsDetailResult>(
                        AppRoutes.goalDetail(goal.id),
                        extra: goal,
                      );

                      if (result == GoalsDetailResult.deleted) {
                        ref.read(goalsListControllerProvider.notifier).refresh();
                      }

                      if (result == GoalsDetailResult.activated) {
                        if (!context.mounted) return;
                        context.pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16.0,
                      ),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      goal.name.isNotEmpty
                          ? goal.name
                          : AppLocalizations.of(context)!.untitledGoal,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
