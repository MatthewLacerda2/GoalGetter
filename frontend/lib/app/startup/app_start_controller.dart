import 'dart:developer' as developer;

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/goals/data/goals_api.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
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
///
/// Any other failure (offline, a 5xx) lands where the last known state points,
/// and that screen's own load shows the failure with a retry (decided in
/// #52): a known active goal ⇒ home, the returning student's usual screen;
/// none ⇒ the goals list, whose `GET /goals` retries this very call.
///
/// The answer to GET /goals is also the server's word on which goal is active,
/// so [ActiveGoal] is set from it.
class AppStartController {
  const AppStartController(
    this._storage,
    this._goals,
    this._activeGoal, {
    required String? Function() knownActiveGoal,
  }) : _knownActiveGoal = knownActiveGoal;

  final SettingsStorage _storage;
  final GoalsApi _goals;
  final ActiveGoal _activeGoal;

  /// The active goal as the app last heard it, for a launch that cannot ask.
  final String? Function() _knownActiveGoal;

  Future<AppStartResult> evaluate() async {
    final token = _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      return const AppStartResult(AppStartDestination.unauthenticated);
    }
    try {
      return AppStartResult(await _decide(await _goals.list()));
    } on ApiException catch (e) {
      if (e.status == 401) {
        return const AppStartResult(AppStartDestination.unauthenticated);
      }
      developer.log('GET /goals failed at startup: $e');
    } on Exception catch (e) {
      developer.log('GET /goals unreachable at startup: $e');
    }
    return AppStartResult(_offlineDestination());
  }

  AppStartDestination _offlineDestination() => _knownActiveGoal() == null
      ? AppStartDestination.authenticatedNeedsActiveGoal
      : AppStartDestination.authenticatedReady;

  Future<AppStartDestination> _decide(List<Goal> goals) async {
    if (goals.isEmpty) return AppStartDestination.authenticatedNeedsGoal;
    final active = activeGoalIn(goals);
    await _activeGoal.set(active);
    return active == null
        ? AppStartDestination.authenticatedNeedsActiveGoal
        : AppStartDestination.authenticatedReady;
  }
}

@riverpod
AppStartController appStartController(Ref ref) {
  return AppStartController(
    ref.watch(settingsStorageProvider),
    ref.watch(goalsApiProvider),
    ref.watch(activeGoalProvider.notifier),
    // Read when asked, not watched: the launch itself sets it, and a watch
    // would ask GET /goals a second time.
    knownActiveGoal: () => ref.read(activeGoalProvider),
  );
}

/// Where the splash (`/`) sends the student: [AppStartController]'s answer,
/// asked once per visit to the splash.
///
/// Auto-disposed and kept alive only by the splash screen watching it, so
/// every visit asks again. The
/// router listens to it without keeping it alive and redirects `/` once it
/// has an answer.
@riverpod
Future<AppStartDestination> launchDestination(Ref ref) async =>
    (await ref.watch(appStartControllerProvider).evaluate()).destination;
