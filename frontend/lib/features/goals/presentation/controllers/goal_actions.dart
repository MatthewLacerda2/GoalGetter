import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/features/goals/data/goals_api.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';

part 'goal_actions.g.dart';

/// What the goal detail screen does to a goal. Each action answers the route to
/// land on, so the screen only navigates; a failed call throws an `ApiFailure`
/// and nothing local changes.
///
/// A change of active goal goes to [ActiveGoal], and whatever is scoped to the
/// active goal follows it from there (#220): nothing here names a screen.
class GoalActions {
  const GoalActions({
    required GoalsApi api,
    required ActiveGoal activeGoal,
    required Future<List<Goal>> Function() reloadGoals,
  })  : _api = api,
        _activeGoal = activeGoal,
        _reloadGoals = reloadGoals;

  final GoalsApi _api;
  final ActiveGoal _activeGoal;
  final Future<List<Goal>> Function() _reloadGoals;

  /// Activates [goal] and lands on home.
  Future<String> setActive(Goal goal) async {
    await _api.setActive(goal.id);
    await _activeGoal.set(goal.id);
    await _refreshQuietly();
    return AppRoutes.home;
  }

  /// Deletes [goal]. The backend clears `current_goal_id` when the active goal
  /// goes, so the app's copy goes too. Lands on goal creation when no goal is
  /// left, else on the goals list; when the list cannot be reloaded, on the
  /// goals list, which shows that failure with a retry.
  Future<String> delete(Goal goal) async {
    await _api.delete(goal.id);
    if (goal.isActive) {
      await _activeGoal.set(null);
    } else {
      await _activeGoal.deleted(goal.id);
    }
    final remaining = await _refreshQuietly();
    if (remaining != null && remaining.isEmpty) return AppRoutes.goalPrompt;
    return AppRoutes.goals;
  }

  /// The action already succeeded: a failed reload is the list's to show.
  Future<List<Goal>?> _refreshQuietly() async {
    try {
      return await _reloadGoals();
    } on Exception {
      return null;
    }
  }
}

@riverpod
GoalActions goalActions(Ref ref) => GoalActions(
      api: ref.watch(goalsApiProvider),
      activeGoal: ref.watch(activeGoalProvider.notifier),
      reloadGoals: () => ref.refresh(goalsListControllerProvider.future),
    );
