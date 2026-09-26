import 'dart:async';
import 'dart:convert';

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
/// - A failed refresh, or a replay that still 401s, clears the session and
///   calls [onSessionExpired] (the app sends the user to the start screen).
/// - Any other non-2xx throws [ApiException] with FastAPI's `detail`.
///
/// Paths are relative to `/api/v1`: `get('/goals')`.
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

  /// Routes that issue tokens or are the refresh itself: a 401 from them is
  /// final, never a reason to refresh.
  static const authPaths = {
    '/auth/signup',
    '/auth/login',
    '/auth/dev-login',
    '/auth/refresh',
    '/auth/logout',
  };

  final http.Client _http;
  final SettingsStorage _storage;
  final String _baseUrl;
  final void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  Future<Object?> get(String path) => send('GET', path);

  Future<Object?> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) =>
      send('POST', path, body: body, headers: headers);

  Future<Object?> put(String path, {Object? body}) =>
      send('PUT', path, body: body);

  Future<Object?> delete(String path) => send('DELETE', path);

  /// Sends the request and returns the decoded JSON body (null when empty).
  Future<Object?> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    var response = await _raw(method, path, body, headers);

    if (response.statusCode == 401 && !authPaths.contains(path)) {
      final refreshed = await _refreshOnce();
      if (refreshed) response = await _raw(method, path, body, headers);
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
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<http.Response> _raw(
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
    return _http.send(request).then(http.Response.fromStream);
  }

  Future<bool> _refreshOnce() {
    return _refreshing ??= _runRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _runRefresh() async {
    final refreshToken = _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await _http.post(
        Uri.parse('$_baseUrl$apiPrefix/auth/refresh'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      await _storage.setAccessToken(data['access_token'] as String);
      await _storage.setRefreshToken(data['refresh_token'] as String);
      return true;
    } on Exception {
      return false;
    }
  }
}
