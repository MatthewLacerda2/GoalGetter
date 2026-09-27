import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/features/resources/data/resources_api.dart';
import 'package:goal_getter/features/resources/domain/resource_item.dart';

part 'resources_controller.g.dart';

/// The active goal's resources, loaded again when it changes. Refresh
/// with `ref.invalidate`.
@riverpod
Future<GoalResources> resources(Ref ref) {
  ref.watch(activeGoalProvider);
  return ref.watch(resourcesApiProvider).fetch();
}

/// True when [error] is the backend saying there is no active goal to read
/// resources for (`no_active_goal`): a retry would get the same answer.
bool isNoActiveGoal(Object error) =>
    error is ApiException && error.code == ErrorCode.noActiveGoal;
