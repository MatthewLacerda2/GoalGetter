import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goals_api.g.dart';

/// The goals endpoints (`backend/api/v1/endpoints/goals.py`), except the
/// onboarding ones. Failures surface as an `ApiFailure`.
class GoalsApi {
  const GoalsApi(this._api);

  final ApiClient _api;

  /// Every goal of the student, newest first.
  Future<List<Goal>> list() => _api.get(
        '/goals',
        (json) => [
          for (final goal in json! as List)
            Goal.fromJson(goal as Map<String, dynamic>),
        ],
      );

  Future<void> setActive(String goalId) =>
      _api.put('/goals/$goalId/set-active', ApiClient.ignoreBody);

  Future<void> delete(String goalId) => _api.delete('/goals/$goalId');
}

@riverpod
GoalsApi goalsApi(Ref ref) => GoalsApi(ref.watch(apiClientProvider));
