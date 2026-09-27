import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/api/api_route.dart';
import 'package:goal_getter/features/resources/domain/resource_item.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'resources_api.g.dart';

/// `GET /resources` (`backend/api/v1/endpoints/resources.py`), scoped by the
/// backend to the active goal. Without one it is `no_active_goal`.
class ResourcesApi {
  const ResourcesApi(this._api);

  final ApiClient _api;

  Future<GoalResources> fetch() => _api.send(
        ApiRoute.resources,
        (json) => GoalResources.fromJson(json! as Map<String, dynamic>),
      );
}

@riverpod
ResourcesApi resourcesApi(Ref ref) =>
    ResourcesApi(ref.watch(apiClientProvider));
