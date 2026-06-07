import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/features/home/debug/mock_home_screen.dart';

/// Provides the Home dashboard data for the active goal.
///
/// Uses a plain [FutureProvider] (not Riverpod codegen) so the new feature
/// compiles without a build_runner pass. Convert to `@riverpod` when wiring the
/// real backend endpoints.
final homeControllerProvider = FutureProvider<MockHomeData>((ref) async {
  return getMockHomeData();
});
