import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goals_api.g.dart';

/// The goals endpoints (`backend/api/v1/endpoints/goals.py`), except the
/// onboarding ones. Failures surface as `ApiException`.
class GoalsApi {
  const GoalsApi(this._api);

  final ApiClient _api;

  /// Every goal of the student, newest first.
  Future<List<Goal>> list() async {
    final body = (await _api.get('/goals'))! as List<dynamic>;
    return body
        .cast<Map<String, dynamic>>()
        .map(Goal.fromJson)
        .toList(growable: false);
  }

  Future<void> setActive(String goalId) =>
      _api.put('/goals/$goalId/set-active');

  Future<void> delete(String goalId) => _api.delete('/goals/$goalId');
}

@riverpod
GoalsApi goalsApi(Ref ref) => GoalsApi(ref.watch(apiClientProvider));
