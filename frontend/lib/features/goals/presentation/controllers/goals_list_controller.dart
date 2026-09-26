import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/features/goals/data/goals_api.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';

part 'goals_list_controller.g.dart';

/// The student's goals (`GET /goals`). The list and the detail screen both read
/// it: there is no per-goal GET. Refresh with `ref.invalidate`.
@riverpod
Future<List<Goal>> goalsListController(Ref ref) {
  return ref.watch(goalsApiProvider).list();
}
