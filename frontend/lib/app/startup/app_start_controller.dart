import 'package:openapi/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/services/openapi_client_factory.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

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

/// Decides which screen the app should show at launch.
class AppStartController {
  const AppStartController({
    required AuthService authService,
    required OpenApiClientFactory openApiClientFactory,
  }) : _authService = authService,
       _openApiClientFactory = openApiClientFactory;

  final AuthService _authService;
  final OpenApiClientFactory _openApiClientFactory;

  Future<AppStartResult> evaluate() async {
    final isSignedIn = await _authService.isSignedIn();

    if (!isSignedIn) {
      // If we only have a Google token, the user hasn't completed signup/onboarding yet.
      // Treat as unauthenticated for routing purposes.
      return const AppStartResult(AppStartDestination.unauthenticated);
    }

    final storedGoalId = SettingsStorage.instance.readCurrentGoalId();

    if (storedGoalId != null && storedGoalId.isNotEmpty) {
      return const AppStartResult(AppStartDestination.authenticatedReady);
    }

    // Missing cached Goal ID: fetch status and persist it.
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

      return const AppStartResult(AppStartDestination.authenticatedReady);
    } catch (_) {
      // If we can't reach the API, prefer letting the user into the app
      // (consistent with prior behavior, where access-token presence implies home).
      return const AppStartResult(AppStartDestination.authenticatedReady);
    }
  }
}

@riverpod
AppStartController appStartController(AppStartControllerRef ref) {
  final authService = ref.watch(authServiceProvider);
  final openApiClientFactory = ref.watch(openApiClientFactoryProvider);
  return AppStartController(
    authService: authService,
    openApiClientFactory: openApiClientFactory,
  );
}
