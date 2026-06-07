import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/features/home/debug/mock_home_screen.dart';

part 'home_controller.g.dart';

/// Provides the Home dashboard data for the active goal.
///
/// Mock-backed for now; swap [getMockHomeData] for the generated API client
/// when the backend exists. See docs/backend_contract.md.
@riverpod
Future<MockHomeData> homeController(HomeControllerRef ref) async {
  return getMockHomeData();
}
