import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:goal_getter/features/goals/debug/mock_resources_screen.dart';

part 'resources_controller.g.dart';

@riverpod
Future<Map<String, List<Map<String, String>>>> resources(ResourcesRef ref) async {
  return await getMockResources();
}
