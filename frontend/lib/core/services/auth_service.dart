import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service.g.dart';

/// Signs the student in and out of the backend.
///
/// Every sign-in ends in [storeSession] with the backend's `token_response`
/// (access token, refresh token, student). Two ways in: Google (the token goes
/// to POST /auth/signup) and, in DEV_LOGIN builds, POST /auth/dev-login.
class AuthService {
  AuthService({required ApiClient api, required SettingsStorage storage})
      : _api = api,
        _storage = storage;

  final ApiClient _api;
  final SettingsStorage _storage;

  static const List<String> _scopes = ['email', 'profile', 'openid'];

  // GoogleSignIn.instance is process-wide and may be initialized only once, so
  // the flag is too.
  static bool _isGoogleInitialized = false;

  /// Initializes GoogleSignIn; needed before the web button renders.
  Future<void> ensureInitialized() async {
    if (_isGoogleInitialized) return;
    await GoogleSignIn.instance.initialize(clientId: AppConfig.googleClientId);
    _isGoogleInitialized = true;
  }

  /// Persists a `token_response` the way the rest of the app reads it.
  Future<void> storeSession(Map<String, dynamic> tokenResponse) async {
    await _storage.setAccessToken(tokenResponse['access_token'] as String);
    await _storage.setRefreshToken(tokenResponse['refresh_token'] as String);
    await _storage.setUserInfo(
      tokenResponse['student'] as Map<String, dynamic>,
    );
  }

  /// Dev only: signs in as the backend's `Fictitious <name>` student.
  Future<void> signInAsFictitious(String name) async {
    final response = await _api.post('/auth/dev-login', body: {'name': name});
    await storeSession(response! as Map<String, dynamic>);
  }

  /// Creates or fetches the student for a Google token (POST /auth/signup is
  /// idempotent) and stores the session.
  Future<void> signupWithGoogle(String googleToken) async {
    final response = await _api.post(
      '/auth/signup',
      headers: {'Authorization': 'Bearer $googleToken'},
    );
    await _storage.setGoogleToken(googleToken);
    await storeSession(response! as Map<String, dynamic>);
  }

  /// Every Google sign-in, as the token POST /auth/signup accepts.
  ///
  /// One stream for both platforms, because the two ways in end in the same
  /// place: on the web only Google's own rendered button may start a sign-in
  /// (see `widgets/google_rendered_button_web.dart`), and it reports the
  /// result *here* and nowhere else; on mobile [startGoogleSignIn] opens
  /// Google's sheet and the plugin publishes the account to this same stream.
  /// So the caller has one thing to listen to and one place that turns an
  /// account into a token.
  ///
  /// A Google-side failure arrives as a stream **error**, so the listener has
  /// something to show the student.
  Stream<String> googleTokens() => GoogleSignIn.instance.authenticationEvents
      .where((event) => event is GoogleSignInAuthenticationEventSignIn)
      .cast<GoogleSignInAuthenticationEventSignIn>()
      .asyncMap((event) => googleTokenFor(event.user));

  /// Opens Google's own sign-in on mobile. The token comes back through
  /// [googleTokens], never from here; this only starts it.
  ///
  /// Throws on the web, where the GIS SDK allows no programmatic sign-in at
  /// all — there, Google's rendered button is the only way in.
  Future<void> startGoogleSignIn() async {
    await ensureInitialized();
    if (kIsWeb) {
      throw UnsupportedError(
        'Programmatic sign-in is not supported on Web. '
        'Use the Google sign-in button instead.',
      );
    }
    try {
      await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
    } on GoogleSignInException catch (e) {
      // Cancelling is not a failure: the student closed Google's sheet.
      if (e.code != GoogleSignInExceptionCode.canceled) rethrow;
    }
  }

  /// The token the backend accepts for [account]: the ID token, else an
  /// access token (the backend verifies both).
  Future<String> googleTokenFor(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken != null) return idToken;
    String? accessToken;
    try {
      accessToken =
          (await account.authorizationClient.authorizeScopes(_scopes))
              .accessToken;
    } on Exception catch (e) {
      developer.log('Google authorizeScopes failed: $e');
      accessToken = (await account.authorizationClient
              .authorizationForScopes(_scopes))
          ?.accessToken;
    }
    if (accessToken == null) {
      throw Exception('Failed to get a token from Google. Please try again.');
    }
    return accessToken;
  }

  bool isSignedIn() {
    final token = _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Sign-out: revoke the refresh token server-side (best effort: a dead
  /// network or an already-revoked token must not keep the student signed
  /// in), sign out of Google if it was ever initialized, then delete every
  /// stored key. The caller navigates to the start screen.
  Future<void> signOut() async {
    final refreshToken = _storage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _api.post(
          '/auth/logout',
          body: {'refresh_token': refreshToken},
        );
      } on Exception catch (e) {
        developer.log('Logout call failed, clearing locally anyway: $e');
      }
    }
    if (_isGoogleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception catch (e) {
        developer.log('Google sign-out failed: $e');
      }
    }
    await _storage.clearAll();
  }
}

@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) {
  return AuthService(
    api: ref.watch(apiClientProvider),
    storage: ref.watch(settingsStorageProvider),
  );
}
