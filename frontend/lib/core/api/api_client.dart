import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:http/http.dart' as http;

/// Resolves `AppConfig.baseUrl`. Empty means the page's own origin on web,
/// where production serves the API next to the bundle under `/api`. A native
/// build has no page origin, so it falls back to production.
String resolveBaseUrl(String configured) {
  final trimmed = configured.trim();
  if (trimmed.isNotEmpty) {
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
  return kIsWeb ? Uri.base.origin : 'https://goalsgetter.org';
}

/// Reads a decoded JSON answer into what the caller wants. Whatever it throws
/// — a failed cast is a `TypeError` — becomes a [MalformedResponse].
typedef JsonReader<T> = T Function(Object? json);

/// The one HTTP client every feature calls the backend through.
///
/// - Adds `Authorization: Bearer <access token>`, read from [SettingsStorage]
///   on every attempt, so a replay after a refresh carries the new token. A
///   caller that sets its own Authorization (signup sends the Google token)
///   keeps it.
/// - On a 401 from a path outside [authPaths], refreshes once and replays the
///   request. The refresh is shared by every request that 401s at the same
///   time: the backend rotates refresh tokens, so N parallel refreshes would
///   revoke each other and log the user out.
/// - A refresh the backend refuses (401: the refresh token is revoked,
///   expired or unknown), or a replay that still 401s, clears the session and
///   calls [onSessionExpired] (the session provider turns false, and the
///   router's redirect sends the user to the start screen).
/// - A refresh that fails for any other reason — a 5xx, no network — keeps the
///   session: it throws the refresh's own [ApiFailure] (never the 401 that
///   triggered it, which screens read as signed-out). Nothing retries it here;
///   the next request that 401s refreshes again (#193).
/// - Everything else that goes wrong is one of the [ApiFailure]s, and nothing
///   else escapes (#221): a non-2xx is [ApiException] with FastAPI's `detail`;
///   an answer the caller's [JsonReader] cannot read is [MalformedResponse];
///   no answer within [timeout] is [TimedOut]; a transport failure is
///   [ServerUnreachable]. All but the [ApiException] are logged here.
///
/// Every call that expects a body takes the reader that turns it into a
/// domain object, so no answer leaves this class unread: a shape the app
/// cannot parse is caught at the one place every answer passes through.
///
/// Paths are relative to `/api/v1`: `get('/goals', readGoals)`.
class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required SettingsStorage storage,
    required String baseUrl,
    this.onSessionExpired,
  })  : _http = httpClient,
        _storage = storage,
        _baseUrl = baseUrl;

  static const apiPrefix = '/api/v1';

  /// How long a request may go unanswered before it is [TimedOut]. Just past
  /// nginx's 60 s `proxy_read_timeout` (`frontend/nginx.conf`): a backend that
  /// is merely slow — a tutor reply waiting on Gemini — is answered by the
  /// proxy first, with a 504, so this only ends a request nothing will ever
  /// answer.
  static const timeout = Duration(seconds: 65);

  /// Routes that issue tokens or are the refresh itself: a 401 from them is
  /// final, never a reason to refresh.
  static const authPaths = {
    '/auth/signup',
    '/auth/login',
    '/auth/dev-login',
    '/auth/refresh',
    '/auth/logout',
  };

  /// The reader of an answer nothing reads.
  static void ignoreBody(Object? json) {}

  final http.Client _http;
  final SettingsStorage _storage;
  final String _baseUrl;
  final void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  Future<T> get<T>(String path, JsonReader<T> read) =>
      _read('GET', path, read);

  Future<T> post<T>(
    String path,
    JsonReader<T> read, {
    Object? body,
    Map<String, String>? headers,
  }) =>
      _read('POST', path, read, body: body, headers: headers);

  Future<T> put<T>(String path, JsonReader<T> read, {Object? body}) =>
      _read('PUT', path, read, body: body);

  Future<void> delete(String path) => _read('DELETE', path, ignoreBody);

  /// Sends the request and reads its answer with [read].
  Future<T> _read<T>(
    String method,
    String path,
    JsonReader<T> read, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final response = await _send(method, path, body, headers);
    return _decode(response, path, read);
  }

  /// The answer to the request, after the refresh-and-replay of a 401; any
  /// non-2xx left is thrown as [ApiException].
  Future<http.Response> _send(
    String method,
    String path,
    Object? body,
    Map<String, String>? headers,
  ) async {
    Future<http.Response> attempt() =>
        _transport(_request(method, path, body, headers), path);
    var response = await attempt();

    if (response.statusCode == 401 && !authPaths.contains(path)) {
      final refreshed = await _refreshOnce();
      if (refreshed) response = await attempt();
      if (!refreshed || response.statusCode == 401) {
        await _storage.clearSession();
        onSessionExpired?.call();
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromBody(
        response.statusCode,
        utf8.decode(response.bodyBytes, allowMalformed: true),
        path: path,
      );
    }
    return response;
  }

  /// The body of a 2xx [response], decoded (null when empty) and read.
  T _decode<T>(http.Response response, String path, JsonReader<T> read) {
    try {
      final bytes = response.bodyBytes;
      return read(bytes.isEmpty ? null : jsonDecode(utf8.decode(bytes)));
      // A failed cast is a TypeError, which `on Exception` would let through.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      developer.log('$path answered in a shape the app cannot read: $e',
          name: 'api');
      throw MalformedResponse(e, path: path);
    }
  }

  http.Request _request(
    String method,
    String path,
    Object? body,
    Map<String, String>? headers,
  ) {
    final request = http.Request(method, Uri.parse('$_baseUrl$apiPrefix$path'))
      ..headers['Accept'] = 'application/json'
      // The student's chosen language, on every request: the backend mirrors
      // it onto students.language (backend/core/language.py, #172).
      ..headers['X-Student-Language'] = _storage.readUserLanguageSync();
    final token = _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (headers != null) request.headers.addAll(headers);
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return request;
  }

  /// Sends [request] and waits at most [timeout] for the whole answer. A
  /// transport failure is [ServerUnreachable]; no answer in time, [TimedOut].
  Future<http.Response> _transport(http.Request request, String path) async {
    try {
      return await _http
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      developer.log('$path got no answer in ${timeout.inSeconds} s',
          name: 'api');
      throw TimedOut(path: path);
    } on Exception catch (e) {
      developer.log('$path could not reach the server: $e', name: 'api');
      throw ServerUnreachable(e, path: path);
    }
  }

  Future<bool> _refreshOnce() {
    return _refreshing ??= _runRefresh().whenComplete(() => _refreshing = null);
  }

  /// True when the tokens were rotated, false when the backend refused the
  /// refresh token (or there is none). Any other failure throws, so every
  /// request sharing this refresh fails with it and the session survives.
  Future<bool> _runRefresh() async {
    const path = '/auth/refresh';
    final refreshToken = _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    final request = http.Request('POST', Uri.parse('$_baseUrl$apiPrefix$path'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json'
      ..body = jsonEncode({'refresh_token': refreshToken});
    final response = await _transport(request, path);
    if (response.statusCode == 401) return false;
    if (response.statusCode != 200) {
      throw ApiException.fromBody(
        response.statusCode,
        utf8.decode(response.bodyBytes, allowMalformed: true),
        path: path,
      );
    }
    final (access, refresh) = _decode(response, path, (json) {
      final data = json! as Map<String, dynamic>;
      return (data['access_token'] as String, data['refresh_token'] as String);
    });
    await _storage.setAccessToken(access);
    await _storage.setRefreshToken(refresh);
    return true;
  }
}
