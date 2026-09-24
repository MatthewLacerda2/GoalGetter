import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/app/startup/app_start_controller.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Launches with [stored] prefs against a backend whose GET /goals answers
/// [goalsBody] with [status].
Future<AppStartDestination> launch(
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
  final result = await AppStartController(storage, api).evaluate();
  return result.destination;
}

const _token = {'access_token': 'access', 'refresh_token': 'r1'};

void main() {
  test('no token goes to the start screen', () async {
    expect(await launch({}), AppStartDestination.unauthenticated);
  });

  test('no goals goes to goal creation', () async {
    expect(await launch(_token), AppStartDestination.authenticatedNeedsGoal);
  });

  test('an active goal goes home', () async {
    final destination = await launch(
      _token,
      goalsBody: '[{"id": "g1", "is_active": false},'
          ' {"id": "g2", "is_active": true}]',
    );
    expect(destination, AppStartDestination.authenticatedReady);
  });

  test('goals but none active goes to the goals list', () async {
    final destination =
        await launch(_token, goalsBody: '[{"id": "g1", "is_active": false}]');
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
