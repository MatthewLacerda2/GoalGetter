import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A backend where only `fresh-access` opens `/goals`, and `/auth/refresh`
/// answers [refreshStatus] — or, with [refreshOffline], never answers at all.
/// Counts the refresh calls.
class FakeBackend {
  FakeBackend({this.refreshStatus = 200, this.refreshOffline = false});

  final int refreshStatus;
  final bool refreshOffline;
  int refreshCalls = 0;

  late final client = MockClient((request) async {
    if (request.url.path == '/api/v1/auth/refresh') {
      refreshCalls++;
      // Let every concurrent 401 arrive before the refresh answers.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (refreshOffline) throw http.ClientException('Connection refused');
      if (refreshStatus == 401) {
        return http.Response(
            '{"detail": "Invalid or expired refresh token"}', 401);
      }
      if (refreshStatus != 200) {
        return http.Response(
            '{"detail": "Internal server error"}', refreshStatus);
      }
      return http.Response(
        jsonEncode({'access_token': 'fresh-access', 'refresh_token': 'r2'}),
        200,
      );
    }
    if (request.headers['Authorization'] == 'Bearer fresh-access') {
      return http.Response('[]', 200);
    }
    return http.Response('{"detail": "Could not validate credentials"}', 401);
  });
}

Future<SettingsStorage> signedInStorage() async {
  SharedPreferences.setMockInitialValues({
    'access_token': 'expired-access',
    'refresh_token': 'r1',
    'user_language': 'en',
  });
  return SettingsStorage(await SharedPreferences.getInstance());
}

void main() {
  test('concurrent 401s share one refresh, then every request is replayed',
      () async {
    final storage = await signedInStorage();
    final backend = FakeBackend();
    final api = ApiClient(
      httpClient: backend.client,
      storage: storage,
      baseUrl: 'http://api.test',
    );

    final results = await Future.wait([api.get('/goals'), api.get('/goals')]);

    expect(backend.refreshCalls, 1);
    expect(results, [<dynamic>[], <dynamic>[]]);
    expect(storage.getAccessToken(), 'fresh-access');
    expect(storage.getRefreshToken(), 'r2');
  });

  test('a refused refresh clears the session and reports it expired',
      () async {
    final storage = await signedInStorage();
    var expired = 0;
    final api = ApiClient(
      httpClient: FakeBackend(refreshStatus: 401).client,
      storage: storage,
      baseUrl: 'http://api.test',
      onSessionExpired: () => expired++,
    );

    await expectLater(
      api.get('/goals'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(expired, 1);
    expect(storage.getAccessToken(), isNull);
    expect(storage.getRefreshToken(), isNull);
    expect(storage.readStoredUserLanguageOrNull(), 'en',
        reason: 'an expired session is not a sign-out: preferences stay');
  });

  test('a refresh the server fails (5xx) keeps the session', () async {
    final storage = await signedInStorage();
    var expired = 0;
    final api = ApiClient(
      httpClient: FakeBackend(refreshStatus: 503).client,
      storage: storage,
      baseUrl: 'http://api.test',
      onSessionExpired: () => expired++,
    );

    await expectLater(
      api.get('/goals'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      reason: 'not a 401: a screen reading 401 as signed-out must not here',
    );
    expect(expired, 0);
    expect(storage.getAccessToken(), 'expired-access');
    expect(storage.getRefreshToken(), 'r1');
  });

  test('a refresh that cannot reach the server keeps the session', () async {
    final storage = await signedInStorage();
    var expired = 0;
    final api = ApiClient(
      httpClient: FakeBackend(refreshOffline: true).client,
      storage: storage,
      baseUrl: 'http://api.test',
      onSessionExpired: () => expired++,
    );

    await expectLater(api.get('/goals'), throwsA(isA<http.ClientException>()));
    expect(expired, 0);
    expect(storage.getRefreshToken(), 'r1');
  });

  test('a 401 from an auth route is final: no refresh', () async {
    final storage = await signedInStorage();
    final backend = FakeBackend();
    final api = ApiClient(
      httpClient: backend.client,
      storage: storage,
      baseUrl: 'http://api.test',
    );

    await expectLater(api.post('/auth/dev-login'), throwsA(isA<ApiException>()));
    expect(backend.refreshCalls, 0);
  });

  test('errors carry the status and FastAPI detail', () {
    final error = ApiException.fromBody(404, '{"detail": "No active goal"}');
    expect(error.status, 404);
    expect(error.detail, 'No active goal');
    expect(ApiException.fromBody(502, '<html>').detail, 'HTTP 502');
  });

  test('every request carries the chosen language', () async {
    final storage = await signedInStorage();
    await storage.writeUserLanguage('pt');
    final sent = <String?>[];
    final api = ApiClient(
      httpClient: MockClient((request) async {
        sent.add(request.headers['X-Student-Language']);
        return http.Response('[]', 200);
      }),
      storage: storage,
      baseUrl: 'http://api.test',
    );

    await api.get('/goals');
    await storage.writeUserLanguage('de');
    await api.post('/auth/dev-login');

    expect(sent, ['pt', 'de']);
  });
}
