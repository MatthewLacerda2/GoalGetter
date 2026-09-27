import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/api_route.dart';
import 'package:goal_getter/core/api/error_code.dart';
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

/// The body as it was decoded.
Object? asIs(Object? json) => json;

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

    final results = await Future.wait([
      api.send(ApiRoute.listGoals, asIs),
      api.send(ApiRoute.listGoals, asIs),
    ]);

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
      api.send(ApiRoute.listGoals, asIs),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(expired, 1);
    expect(storage.getAccessToken(), isNull);
    expect(storage.getRefreshToken(), isNull);
    expect(storage.readUserLanguageSync(), 'en',
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
      api.send(ApiRoute.listGoals, asIs),
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

    await expectLater(
      api.send(ApiRoute.listGoals, asIs),
      throwsA(isA<ServerUnreachable>()),
    );
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

    await expectLater(
      api.send(ApiRoute.devLogin, asIs),
      throwsA(isA<ApiException>()),
    );
    expect(backend.refreshCalls, 0);
  });

  test('errors carry the status, the code and the detail', () {
    final error = ApiException.fromBody(
      404,
      '{"code": "no_active_goal", "detail": "No active goal"}',
    );
    expect(error.status, 404);
    expect(error.code, ErrorCode.noActiveGoal);
    expect(error.detail, 'No active goal');
    final proxyPage = ApiException.fromBody(502, '<html>');
    expect((proxyPage.code, proxyPage.detail), (null, 'HTTP 502'));
    final newer = ApiException.fromBody(418, '{"code": "from_the_future"}');
    expect(newer.code, isNull);
  });

  test('Gemini refusing our key is a 5xx: the student stays signed in',
      () async {
    // #214: Gemini's own 401 must not reach the app as a 401 and sign him out.
    final storage = await signedInStorage();
    var expired = false;
    final api = ApiClient(
      httpClient: MockClient((_) async => http.Response(
            '{"code": "gemini_key_rejected", "detail": "Gemini refused"}',
            502,
          )),
      storage: storage,
      baseUrl: 'http://api.test',
      onSessionExpired: () => expired = true,
    );

    await expectLater(
      api.send(ApiRoute.sendTutorMessage, asIs, body: {'message': 'hi'}),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ErrorCode.geminiKeyRejected)),
    );
    expect(expired, isFalse);
    expect(storage.getAccessToken(), 'expired-access');
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

    await api.send(ApiRoute.listGoals, asIs);
    await storage.writeUserLanguage('de');
    await api.send(ApiRoute.devLogin, asIs);

    expect(sent, ['pt', 'de']);
  });

  group('every failure is an ApiFailure (#221)', () {
    Future<ApiClient> answering(Future<http.Response> Function() reply) async =>
        ApiClient(
          httpClient: MockClient((_) => reply()),
          storage: await signedInStorage(),
          baseUrl: 'http://api.test',
        );

    test('a body the reader cannot read is a MalformedResponse', () async {
      final api = await answering(() async => http.Response('{"a": 1}', 200));
      await expectLater(
        api.send(ApiRoute.listGoals, (json) => json! as List),
        throwsA(
          isA<MalformedResponse>()
              .having((e) => e.path, 'path', '/goals')
              .having((e) => e.cause, 'cause', isA<TypeError>()),
        ),
      );
    });

    test('a 2xx that is not JSON is a MalformedResponse', () async {
      final api = await answering(() async => http.Response('<html>', 200));
      await expectLater(
        api.send(ApiRoute.listGoals, asIs),
        throwsA(isA<MalformedResponse>()),
      );
    });

    test('a transport failure is ServerUnreachable', () async {
      final api = await answering(
        () async => throw http.ClientException('Connection refused'),
      );
      await expectLater(
        api.send(ApiRoute.listGoals, asIs),
        throwsA(isA<ServerUnreachable>()),
      );
    });

    testWidgets('no answer within the timeout is TimedOut', (tester) async {
      final api = await answering(() => Completer<http.Response>().future);
      Object? failure;
      unawaited(api.send(ApiRoute.listGoals, asIs).then<void>(
            (_) {},
            onError: (Object e) => failure = e,
          ));

      await tester.pump(ApiClient.timeout - const Duration(seconds: 1));
      expect(failure, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(failure, isA<TimedOut>());
    });
  });

  test('a route fills its placeholders and appends its query', () async {
    final urls = <String>[];
    final api = ApiClient(
      httpClient: MockClient((request) async {
        urls.add('${request.method} ${request.url}');
        return http.Response('[]', 200);
      }),
      storage: await signedInStorage(),
      baseUrl: 'http://api.test',
    );

    await api.send(ApiRoute.setActiveGoal, ApiClient.ignoreBody,
        params: {'goal_id': 'a b'});
    await api.send(ApiRoute.tutorMessages, asIs, query: {'limit': '20'});

    expect(urls, [
      'PUT http://api.test/api/v1/goals/a%20b/set-active',
      'GET http://api.test/api/v1/tutor/messages?limit=20',
    ]);
    expect(() => ApiRoute.setActiveGoal.path(), throwsArgumentError,
        reason: 'a placeholder left unfilled is a programming error');
  });
}
