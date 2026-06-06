import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:openapi/api.dart';
import 'package:goal_getter/core/services/openapi_client_factory.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

part 'goals_list_controller.g.dart';

@riverpod
class GoalsListController extends _$GoalsListController {
  @override
  FutureOr<List<GoalListItem>> build() async {
    return _fetchGoals();
  }

  Future<List<GoalListItem>> _fetchGoals() async {
    final apiClient = await ref.read(openApiClientFactoryProvider).createAuthorized();
    final goalsApi = GoalsApi(apiClient);
    final goalsResponse = await goalsApi.listGoalsApiV1GoalsGet();
    return goalsResponse?.goals ?? [];
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGoals());
  }

  Future<void> deleteGoal(String goalId) async {
    final apiClient = await ref.read(openApiClientFactoryProvider).createAuthorized();
    final goalsApi = GoalsApi(apiClient);
    await goalsApi.deleteGoalApiV1GoalsGoalIdDelete(goalId);
    await refresh();
  }

  Future<dynamic> selectGoal(GoalListItem goal) async {
    final apiClient = await ref.read(openApiClientFactoryProvider).createAuthorized();
    final goalsApi = GoalsApi(apiClient);
    final response = await goalsApi.setActiveGoalApiV1GoalsGoalIdSetActivePut(goal.id);
    if (response != null && response.goalId != null) {
      await SettingsStorage.setCurrentGoalId(response.goalId!);
    }
    return response;
  }
}
