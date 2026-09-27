import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/auth_api.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../contract/contract_client.dart';
import '../contract/error_body.dart';

/// Every key the app stores, so sign-out has something to delete.
const _everything = {
  'access_token': 'access',
  'refresh_token': 'r1',
  'user_info': '{"name": "Fictitious Claude"}',
  'current_goal_id': 'goal-1',
  'user_language': 'fr',
  'notifications_on': true,
};

Future<(AuthService, SharedPreferences, List<http.Request>)> signedIn(
  int logoutStatus, {
  void Function()? onSessionChanged,
}) async {
  SharedPreferences.setMockInitialValues(_everything);
  final prefs = await SharedPreferences.getInstance();
  final sent = <http.Request>[];
  final client = contractClient((request) async {
    sent.add(request);
    final ok = logoutStatus < 300;
    return http.Response(
      ok ? '' : crashed,
      logoutStatus,
    );
  });
  final storage = SettingsStorage(prefs);
  final api = ApiClient(
    httpClient: client,
    storage: storage,
    baseUrl: 'http://api.test',
  );
  final auth = AuthService(
    api: AuthApi(api),
    storage: storage,
    onSessionChanged: onSessionChanged,
  );
  return (auth, prefs, sent);
}

void main() {
  test('sign-out revokes the refresh token, then deletes every key', () async {
    final (auth, prefs, sent) = await signedIn(204);

    await auth.signOut();

    expect(sent.single.url.path, '/api/v1/auth/logout');
    expect(jsonDecode(sent.single.body), {'refresh_token': 'r1'});
    expect(prefs.getKeys(), isEmpty);
  });

  test('sign-out still deletes every key when logout fails', () async {
    final (auth, prefs, _) = await signedIn(500);

    await auth.signOut();

    expect(prefs.getKeys(), isEmpty);
  });

  test('sign-out tells the session, once every key is gone', () async {
    List<String>? keysWhenTold;
    late SharedPreferences prefs;
    final (auth, p, _) = await signedIn(
      204,
      onSessionChanged: () => keysWhenTold = prefs.getKeys().toList(),
    );
    prefs = p;

    await auth.signOut();

    expect(keysWhenTold, isEmpty,
        reason: 'the router reads the session when told: it must be gone');
  });
}
