import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/api/api_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_api.g.dart';

/// POST /auth/signup, /auth/dev-login and /auth/logout
/// (`backend/api/v1/endpoints/auth.py`): the calls that start and end a
/// session.
///
/// They sit beside the transport rather than in a feature's `data/`, because a
/// session is no one feature's: the start screen starts it, the profile ends
/// it, and the client refreshes it. `AuthService` decides what to do with
/// them; this is only the wire.
class AuthApi {
  const AuthApi(this._api);

  final ApiClient _api;

  /// Creates or fetches the student for a Google token (idempotent).
  Future<SessionTokens> signup(String googleToken) => _api.send(
    ApiRoute.signup,
    SessionTokens.fromResponse,
    headers: {'Authorization': 'Bearer $googleToken'},
  );

  /// Dev only: the backend's `Fictitious <name>` student.
  Future<SessionTokens> devLogin(String name) => _api.send(
    ApiRoute.devLogin,
    SessionTokens.fromResponse,
    body: {'name': name},
  );

  /// Revokes [refreshToken] server-side.
  Future<void> logout(String refreshToken) => _api.send(
    ApiRoute.logout,
    ApiClient.ignoreBody,
    body: {'refresh_token': refreshToken},
  );
}

/// The two tokens of a backend `token_response`, which every sign-in returns.
class SessionTokens {
  const SessionTokens({required this.accessToken, required this.refreshToken});

  /// Checked where it is read: another shape is then the client's
  /// `MalformedResponse`, not a `TypeError` inside whoever stores it.
  factory SessionTokens.fromResponse(Object? json) {
    final response = json! as Map<String, dynamic>;
    if (response['access_token'] is! String ||
        response['refresh_token'] is! String ||
        response['student'] is! Map<String, dynamic>) {
      throw const FormatException('not a token_response');
    }
    return SessionTokens(
      accessToken: response['access_token'] as String,
      refreshToken: response['refresh_token'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
}

@Riverpod(keepAlive: true)
AuthApi authApi(Ref ref) => AuthApi(ref.watch(apiClientProvider));
