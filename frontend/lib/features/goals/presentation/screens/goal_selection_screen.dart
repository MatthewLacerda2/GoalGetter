import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';

import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_prompt_screen.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  late final AuthService _authService = ref.read(authServiceProvider);
  bool _isActionInProgress = false;

  Future<void> _selectGoal(GoalListItem goal) async {
    setState(() => _isActionInProgress = true);

    try {
      final accessToken = await _authService.getStoredAccessToken();
      final response = await ref.read(goalsListControllerProvider.notifier).selectGoal(goal);

      if (response != null) {
        if (mounted) {
          if (accessToken != null && accessToken.isNotEmpty) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.goalPrompt);
          }
        }
      } else {
        throw Exception('Failed to set active goal: No response received');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting goal: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  Future<void> _deleteGoal(GoalListItem goal, List<GoalListItem> currentGoals) async {
    // First confirmation dialog
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteGoal),
          content: Text(AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisGoal),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirm1 != true) return;

    if (!mounted) return;

    // Second confirmation dialog
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.warning),
          content: Text(AppLocalizations.of(context)!.deleteGoalWarningDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirm2 != true) return;

    setState(() => _isActionInProgress = true);

    try {
      await ref.read(goalsListControllerProvider.notifier).deleteGoal(goal.id);

      // If no goals left after deletion, navigate to goal prompt screen
      if (currentGoals.length <= 1 && mounted) {
        await SettingsStorage.clearCurrentGoal();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => GoalPromptScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting goal: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsListControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectGoal),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Stack(
        children: [
          goalsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $err',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => ref.read(goalsListControllerProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (goals) {
              if (goals.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.noGoalsFound,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => GoalPromptScreen()),
                          );
                        },
                        child: Text(AppLocalizations.of(context)!.createFirstGoal),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return Dismissible(
                    key: Key(goal.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24.0),
                      color: Theme.of(context).colorScheme.error,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      await _deleteGoal(goal, goals);
                      return false;
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      color: Colors.transparent,
                      elevation: 0,
                      child: ElevatedButton(
                        onPressed: () => _selectGoal(goal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16.0),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.name.isNotEmpty
                                  ? goal.name
                                  : AppLocalizations.of(context)!.untitledGoal,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                            if (goal.description.isNotEmpty) ...[
                              const SizedBox(height: 8.0),
                              Text(
                                goal.description,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 14.0,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isActionInProgress)
            Container(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => GoalPromptScreen()),
          );
          ref.read(goalsListControllerProvider.notifier).refresh();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.createNewGoal),
      ),
    );
  }
}
