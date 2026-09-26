import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/goals/data/goals_api.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';
import 'package:goal_getter/features/resources/presentation/controllers/resources_controller.dart';

part 'goal_actions.g.dart';

/// What the goal detail screen does to a goal. Each action answers the route to
/// land on, so the screen only navigates; a failed call throws (`ApiException`,
/// or the transport's exception) and nothing local changes.
class GoalActions {
  const GoalActions({
    required GoalsApi api,
    required SettingsStorage storage,
    required Future<List<Goal>> Function() reloadGoals,
    void Function()? onActiveGoalChanged,
  })  : _api = api,
        _storage = storage,
        _reloadGoals = reloadGoals,
        _onActiveGoalChanged = onActiveGoalChanged;

  final GoalsApi _api;
  final SettingsStorage _storage;
  final Future<List<Goal>> Function() _reloadGoals;

  /// Drops what was read for the previous active goal (the goal-scoped reads:
  /// resources today; home and the tutor once they read the API).
  final void Function()? _onActiveGoalChanged;

  /// Activates [goal], remembers it as the active goal, and lands on home.
  Future<String> setActive(Goal goal) async {
    await _api.setActive(goal.id);
    await _storage.writeCurrentGoalId(goal.id);
    _onActiveGoalChanged?.call();
    await _refreshQuietly();
    return AppRoutes.home;
  }

  /// Deletes [goal]. The backend clears `current_goal_id` when the active goal
  /// goes, so the stored id goes too. Lands on goal creation when no goal is
  /// left, else on the goals list; when the list cannot be reloaded, on the
  /// goals list, which shows that failure with a retry.
  Future<String> delete(Goal goal) async {
    await _api.delete(goal.id);
    if (goal.isActive || _storage.readCurrentGoalId() == goal.id) {
      await _storage.deleteCurrentGoal();
      _onActiveGoalChanged?.call();
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
      storage: ref.watch(settingsStorageProvider),
      reloadGoals: () => ref.refresh(goalsListControllerProvider.future),
      onActiveGoalChanged: () => ref.invalidate(resourcesProvider),
    );
