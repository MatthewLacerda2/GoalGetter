import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/features/goals/data/goals_api.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';

part 'goals_list_controller.g.dart';

/// The student's goals (`GET /goals`). The list and the detail screen both read
/// it: there is no per-goal GET. Refresh with `ref.invalidate`.
///
/// Each answer also says which goal the server holds active, and the app's
/// copy ([ActiveGoal]) follows it: a goal switched on another device reaches
/// Home and the Tutor the next time this list loads.
@riverpod
Future<List<Goal>> goalsListController(Ref ref) async {
  final goals = await ref.watch(goalsApiProvider).list();
  if (ref.mounted) {
    await ref.read(activeGoalProvider.notifier).set(activeGoalIn(goals));
  }
  return goals;
}
