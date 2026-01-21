import 'package:openapi/api.dart';

import '../../services/auth_service.dart';
import '../../services/openapi_client_factory.dart';
import '../../utils/settings_storage.dart';

enum AppStartDestination {
  unauthenticated,
  authenticatedNeedsGoal,
  authenticatedReady,
}

class AppStartResult {
  const AppStartResult(this.destination);

  final AppStartDestination destination;
}

/// Decides which screen the app should show at launch.
///
/// This consolidates the startup auth/onboarding orchestration that used to live
/// directly inside a widget state object.
class AppStartController {
  AppStartController({
    AuthService? authService,
    OpenApiClientFactory? openApiClientFactory,
  }) : _authService = authService ?? AuthService(),
       _openApiClientFactory =
           openApiClientFactory ??
           OpenApiClientFactory(authService: authService ?? AuthService());

  final AuthService _authService;
  final OpenApiClientFactory _openApiClientFactory;

  Future<AppStartResult> evaluate() async {
    final isSignedIn = await _authService.isSignedIn();

    if (!isSignedIn) {
      // If we only have a Google token, the user hasn't completed signup/onboarding yet.
      // Treat as unauthenticated for routing purposes.
      return const AppStartResult(AppStartDestination.unauthenticated);
    }

    // We have an access token: user has completed signup.
    // Decide if we can land in the main app or we must go to goal onboarding.
    final storedGoalId = await SettingsStorage.getCurrentGoalId();
    final storedObjectiveId = await SettingsStorage.getCurrentObjectiveId();

    if (storedGoalId != null &&
        storedGoalId.isNotEmpty &&
        storedObjectiveId != null &&
        storedObjectiveId.isNotEmpty) {
      return const AppStartResult(AppStartDestination.authenticatedReady);
    }

    // Missing cached IDs: fetch status and best-effort persist IDs.
    try {
      final apiClient = await _openApiClientFactory.createWithAccessToken();

      final studentApi = StudentApi(apiClient);
      final studentStatus = await studentApi
          .getStudentCurrentStatusApiV1StudentGet();

      final goalId = studentStatus?.goalId;
      if (goalId == null || goalId.isEmpty) {
        return const AppStartResult(AppStartDestination.authenticatedNeedsGoal);
      }

      await SettingsStorage.setCurrentGoalId(goalId);

      // Best-effort objective cache.
      try {
        final objectiveApi = ObjectiveApi(apiClient);
        final objective = await objectiveApi.getObjectiveApiV1ObjectiveGet();
        if (objective != null && objective.id.isNotEmpty) {
          await SettingsStorage.setCurrentObjectiveId(objective.id);
        }
      } catch (_) {
        // Best-effort only.
      }

      return const AppStartResult(AppStartDestination.authenticatedReady);
    } catch (_) {
      // If we can't reach the API, prefer letting the user into the app
      // (consistent with prior behavior, where access-token presence implies home).
      return const AppStartResult(AppStartDestination.authenticatedReady);
    }
  }
}
