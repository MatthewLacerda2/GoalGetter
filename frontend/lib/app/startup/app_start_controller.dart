import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_start_controller.g.dart';

enum AppStartDestination {
  unauthenticated,
  authenticatedNeedsGoal,
  authenticatedReady,
}

class AppStartResult {
  const AppStartResult(this.destination);

  final AppStartDestination destination;
}

/// Decides which screen the app shows at launch.
///
/// MOCK: auth/backend isn't wired yet, so we pretend a returning user with an
/// active goal (7 days of usage) and route straight to the Home dashboard.
/// Restore the real auth + active-goal checks here once the backend exists
/// (see docs/backend_contract.md — GET /me, GET /goals).
class AppStartController {
  const AppStartController();

  Future<AppStartResult> evaluate() async {
    return const AppStartResult(AppStartDestination.authenticatedReady);
  }
}

@riverpod
AppStartController appStartController(AppStartControllerRef ref) {
  return const AppStartController();
}
