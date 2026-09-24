import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/features/resources/data/resources_api.dart';
import 'package:goal_getter/features/resources/domain/resource_item.dart';

part 'resources_controller.g.dart';

/// The active goal's resources. Refresh with `ref.invalidate`.
@riverpod
Future<GoalResources> resources(ResourcesRef ref) {
  return ref.watch(resourcesApiProvider).fetch();
}
