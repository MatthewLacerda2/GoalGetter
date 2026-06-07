import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/debug/mock_goals.dart';

part 'goals_list_controller.g.dart';

/// Provides the user's goals. Mock-backed while the backend doesn't exist;
/// refresh via `ref.invalidate`. See docs/backend_contract.md (GET /goals).
@riverpod
Future<List<Goal>> goalsListController(GoalsListControllerRef ref) async {
  return getMockGoals();
}
