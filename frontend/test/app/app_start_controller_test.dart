import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/app/startup/app_start_controller.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Launches with [stored] prefs against a backend whose GET /goals answers
/// [goalsBody] with [status]. Returns where it went, and the active goal the
/// app then holds.
Future<(AppStartDestination, String?)> launchAndHold(
  Map<String, Object> stored, {
  String goalsBody = '[]',
  int status = 200,
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final storage = SettingsStorage(await SharedPreferences.getInstance());
  final api = ApiClient(
    httpClient: MockClient((_) async => http.Response(goalsBody, status)),
    storage: storage,
    baseUrl: 'http://api.test',
  );
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [
      settingsStorageProvider.overrideWithValue(storage),
      apiClientProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  final result = await container.read(appStartControllerProvider).evaluate();
  return (result.destination, container.read(activeGoalProvider));
}

Future<AppStartDestination> launch(
  Map<String, Object> stored, {
  String goalsBody = '[]',
  int status = 200,
}) async =>
    (await launchAndHold(stored, goalsBody: goalsBody, status: status)).$1;

const _token = {'access_token': 'access', 'refresh_token': 'r1'};

/// One item of GET /goals, as the backend sends it.
String _goal(String id, {required bool active}) =>
    '{"id": "$id", "name": "Chess", "description": "Openings.",'
    ' "current_elo": 1000, "is_active": $active}';

void main() {
  test('no token goes to the start screen', () async {
    expect(await launch({}), AppStartDestination.unauthenticated);
  });

  test('no goals goes to goal creation', () async {
    expect(await launch(_token), AppStartDestination.authenticatedNeedsGoal);
  });

  test('an active goal goes home, and is the one the app holds', () async {
    final (destination, active) = await launchAndHold(
      {..._token, 'current_goal_id': 'g1'},
      goalsBody:
          '[${_goal('g1', active: false)}, ${_goal('g2', active: true)}]',
    );
    expect(destination, AppStartDestination.authenticatedReady);
    expect(active, 'g2', reason: "the server's word, not the device's");
  });

  test('goals but none active goes to the goals list', () async {
    final destination =
        await launch(_token, goalsBody: '[${_goal('g1', active: false)}]');
    expect(destination, AppStartDestination.authenticatedNeedsActiveGoal);
  });

  test('a failed GET /goals with a stored active goal goes home', () async {
    final destination = await launch(
      {..._token, 'current_goal_id': 'g1'},
      goalsBody: '{"detail": "boom"}',
      status: 500,
    );
    expect(destination, AppStartDestination.authenticatedReady);
  });

  test('a failed GET /goals without one goes to the goals list', () async {
    final destination =
        await launch(_token, goalsBody: '{"detail": "boom"}', status: 500);
    expect(destination, AppStartDestination.authenticatedNeedsActiveGoal);
  });
}
