import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/debug/mock_goals.dart';

/// Provides the user's goals. Mock-backed (plain FutureProvider, no codegen)
/// while the backend doesn't exist; refresh via `ref.invalidate`.
/// See docs/backend_contract.md (GET /goals).
final goalsListControllerProvider = FutureProvider<List<Goal>>((ref) async {
  return getMockGoals();
});
