import 'dart:developer' as developer;

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_start_controller.g.dart';

enum AppStartDestination {
  unauthenticated,
  authenticatedNeedsGoal,
  authenticatedNeedsActiveGoal,
  authenticatedReady;

  /// The route each destination lands on.
  String get location => switch (this) {
        unauthenticated => AppRoutes.start,
        authenticatedNeedsGoal => AppRoutes.goalPrompt,
        authenticatedNeedsActiveGoal => AppRoutes.goals,
        authenticatedReady => AppRoutes.home,
      };
}

class AppStartResult {
  const AppStartResult(this.destination);

  final AppStartDestination destination;
}

/// Decides which screen the app shows at launch, and right after a sign-in.
///
/// No stored token ⇒ the start screen. A token ⇒ GET /goals: an active goal
/// ⇒ home, goals but none active ⇒ the goals list, no goals ⇒ goal creation.
/// A 401 the client could not refresh has already cleared the session, so it
/// reads as signed out.
// TODO(MatthewLacerda2): GET /goals is built in #52. Until it is on the
// backend the call fails (405), and any failure other than a 401 falls back to
// home, which #51 accepted; offline, home is still the right answer for a
// returning student.
class AppStartController {
  const AppStartController(this._storage, this._api);

  final SettingsStorage _storage;
  final ApiClient _api;

  Future<AppStartResult> evaluate() async {
    final token = _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return const AppStartResult(AppStartDestination.unauthenticated);
    }
    try {
      final goals = (await _api.get('/goals'))! as List<dynamic>;
      return AppStartResult(await _decide(goals.cast<Map<String, dynamic>>()));
    } on ApiException catch (e) {
      if (e.status == 401) {
        return const AppStartResult(AppStartDestination.unauthenticated);
      }
      developer.log('GET /goals failed at startup, going home: $e');
    } on Exception catch (e) {
      developer.log('GET /goals unreachable at startup, going home: $e');
    }
    return const AppStartResult(AppStartDestination.authenticatedReady);
  }

  Future<AppStartDestination> _decide(List<Map<String, dynamic>> goals) async {
    if (goals.isEmpty) return AppStartDestination.authenticatedNeedsGoal;
    for (final goal in goals) {
      if (goal['is_active'] == true) {
        await _storage.writeCurrentGoalId(goal['id'] as String);
        return AppStartDestination.authenticatedReady;
      }
    }
    await _storage.deleteCurrentGoal();
    return AppStartDestination.authenticatedNeedsActiveGoal;
  }
}

@riverpod
AppStartController appStartController(AppStartControllerRef ref) {
  return AppStartController(
    ref.watch(settingsStorageProvider),
    ref.watch(apiClientProvider),
  );
}
