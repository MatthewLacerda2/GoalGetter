import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/resources/domain/resource_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'resources_api.g.dart';

/// `GET /resources` (`backend/api/v1/endpoints/resources.py`), scoped by the
/// backend to the active goal. Without one it is 404 `No active goal`
/// ([noActiveGoalDetail]).
class ResourcesApi {
  const ResourcesApi(this._api);

  /// The backend's `detail` for a goal-scoped read with no active goal
  /// (`backend/api/v1/goal_dependencies.py::get_active_goal`).
  static const noActiveGoalDetail = 'No active goal';

  final ApiClient _api;

  Future<GoalResources> fetch() async {
    final body = (await _api.get('/resources'))! as Map<String, dynamic>;
    return GoalResources.fromJson(body);
  }
}

@riverpod
ResourcesApi resourcesApi(Ref ref) =>
    ResourcesApi(ref.watch(apiClientProvider));
