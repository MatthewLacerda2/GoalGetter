import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

import 'package:goal_getter/core/config/app_config.dart';

part 'auth_service.g.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Storage and keys are managed by SettingsStorage

  // Google Sign-In client ID
  static const String _clientId = AppConfig.googleClientId;

  // Scopes for Google Sign-In
  static const List<String> _scopes = ['email', 'profile', 'openid'];

  // Track initialization state
  bool _isInitialized = false;

  // Ensure GoogleSignIn is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await GoogleSignIn.instance.initialize(clientId: _clientId);
      _isInitialized = true;
    }
  }

  // Public method to ensure GoogleSignIn is initialized (needed for Web button rendering)
  Future<void> ensureInitialized() async {
    await _ensureInitialized();
  }

  // Sign in with Google and return the ID token or access token
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    developer.log("EA SPORTS, its in the game");
    try {
      await _ensureInitialized();
      developer.log('Starting Google Sign-In...');

      if (kIsWeb) {
        throw UnsupportedError('Programmatic sign-in is not supported on Web. Use the Google sign-in button instead.');
      }

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate(scopeHint: _scopes);

      if (googleUser == null) {
        developer.log('Google user is null (cancelled)');
        return null;
      }

      developer.log('Google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      developer.log(
        'ID Token: ${googleAuth.idToken != null ? "Present" : "NULL"}',
      );

      final String? idToken = googleAuth.idToken;

      // Get access token via authorization client as fallback
      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
            .authorizeScopes(_scopes);
        accessToken = authorization.accessToken;
        developer.log('Access Token: Present');
      } catch (e) {
        developer.log('Failed to get access token: $e');
        // Try to get existing authorization without prompting
        final existingAuth = await googleUser.authorizationClient
            .authorizationForScopes(_scopes);
        accessToken = existingAuth?.accessToken;
        developer.log(
          'Access Token (existing): ${accessToken != null ? "Present" : "NULL"}',
        );
      }

      // Use ID token if available, otherwise fall back to access token
      // Backend supports both ID tokens and access tokens
      final String? tokenToUse = idToken ?? accessToken;

      if (tokenToUse == null) {
        developer.log('Both ID token and access token are null');
        throw Exception(
          'Failed to get token from Google. Please try signing in again.',
        );
      }

      if (idToken == null) {
        developer.log('ID Token is null, using access token instead');
      }

      // Store token temporarily and persistently
      _tempGoogleToken = tokenToUse;
      await storeGoogleToken(tokenToUse);

      _tempUserInfo = {
        'sub': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'picture': googleUser.photoUrl,
      };

      developer.log('Successfully authenticated user: ${googleUser.email}');
      return {'token': tokenToUse, 'user': _tempUserInfo};
    } on GoogleSignInException catch (e) {
      // Handle cancellation or other Google Sign-In specific errors
      if (e.code == GoogleSignInExceptionCode.canceled) {
        developer.log('User cancelled sign-in');
        return null;
      }
      developer.log('Google Sign-In error: ${e.code} - ${e.description}');
      rethrow;
    } catch (error) {
      developer.log('Error signing in to your app with Google: $error');
      rethrow;
    }
  }

  // Handle GoogleSignInAccount directly (e.g. from the stream on Web)
  Future<Map<String, dynamic>?> handleGoogleSignInAccount(GoogleSignInAccount? googleUser) async {
    try {
      if (googleUser == null) {
        developer.log('Google user is null');
        return null;
      }

      developer.log('Google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      developer.log(
        'ID Token: ${googleAuth.idToken != null ? "Present" : "NULL"}',
      );

      final String? idToken = googleAuth.idToken;

      // Get access token via authorization client as fallback
      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
            .authorizeScopes(_scopes);
        accessToken = authorization.accessToken;
        developer.log('Access Token: Present');
      } catch (e) {
        developer.log('Failed to get access token: $e');
        // Try to get existing authorization without prompting
        final existingAuth = await googleUser.authorizationClient
            .authorizationForScopes(_scopes);
        accessToken = existingAuth?.accessToken;
        developer.log(
          'Access Token (existing): ${accessToken != null ? "Present" : "NULL"}',
        );
      }

      final String? tokenToUse = idToken ?? accessToken;

      if (tokenToUse == null) {
        developer.log('Both ID token and access token are null');
        throw Exception(
          'Failed to get token from Google. Please try signing in again.',
        );
      }

      // Store token temporarily and persistently
      _tempGoogleToken = tokenToUse;
      await storeGoogleToken(tokenToUse);

      _tempUserInfo = {
        'sub': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'picture': googleUser.photoUrl,
      };

      developer.log('Successfully authenticated user: ${googleUser.email}');
      return {'token': tokenToUse, 'user': _tempUserInfo};
    } catch (error) {
      developer.log('Error handling Google sign-in account: $error');
      rethrow;
    }
  }

  // In-memory storage for OAuth data during onboarding
  String? _tempGoogleToken;
  Map<String, dynamic>? _tempUserInfo;

  // Get temporary Google token (in memory)
  String? getTempGoogleToken() {
    return _tempGoogleToken;
  }

  // Get temporary user info (in memory)
  Map<String, dynamic>? getTempUserInfo() {
    return _tempUserInfo;
  }

  // Check if we have temporary OAuth data (for onboarding)
  bool hasTempAuthData() {
    return _tempGoogleToken != null && _tempUserInfo != null;
  }

  // Store final credentials after successful onboarding
  Future<void> storeFinalCredentials(
    String accessToken,
    Map<String, dynamic> userInfo,
  ) async {
    final storage = SettingsStorage.instance;
    await storage.setAccessToken(accessToken);
    await storage.setUserInfo(userInfo);

    // Clear temporary data
    _tempGoogleToken = null;
    _tempUserInfo = null;
  }

  // Get stored access token (after onboarding completion)
  Future<String?> getStoredAccessToken() async {
    return SettingsStorage.instance.getAccessToken();
  }

  // Get stored user info (after onboarding completion)
  Future<Map<String, dynamic>?> getStoredUserInfo() async {
    return SettingsStorage.instance.getUserInfo();
  }

  // Check if user has completed onboarding and is signed in
  Future<bool> isSignedIn() async {
    final token = await getStoredAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Sign out (clear both memory and storage).
  //
  // The Google sign-out is best-effort: a returning user goes straight from the
  // AuthGate to /home (see auth_gate.dart) without ever initializing
  // GoogleSignIn, so calling signOut() on it throws a StateError. Guard it so a
  // failure there never blocks clearing local data — the part that actually
  // signs the user out of this app.
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (error) {
      developer.log('Google sign-out skipped (not initialized / failed): $error');
    }

    await SettingsStorage.instance.clearAuthData();

    // Clear temporary data
    _tempGoogleToken = null;
    _tempUserInfo = null;
  }

  // Clear temporary OAuth data (if user cancels onboarding)
  void clearTempAuthData() {
    _tempGoogleToken = null;
    _tempUserInfo = null;
  }

  // Store Google token in SharedPreferences
  Future<void> storeGoogleToken(String token) async {
    await SettingsStorage.instance.setGoogleToken(token);
  }

  // Get stored Google token from SharedPreferences
  Future<String?> getStoredGoogleToken() async {
    return SettingsStorage.instance.getGoogleToken();
  }

  // Sign up with Google.
  //
  // Mock: the backend doesn't exist yet, so instead of calling the real signup
  // endpoint we fabricate a session and store it. The shape returned here mirrors
  // what the future endpoint will give back (an access token + a student record);
  // see the mock_* files for the data the backend needs to provide.
  Future<Map<String, dynamic>?> signupWithGoogle(String googleToken) async {
    developer.log('Mock signupWithGoogle (no backend call)');

    const accessToken = 'mock_access_token_jwt';
    final studentData = {
      'id': 'mock_student_id',
      'email': _tempUserInfo?['email'] ?? 'mockuser@example.com',
      'name': _tempUserInfo?['name'] ?? 'Mock GoalGetter Student',
    };

    // Store both the Google token and the (mock) JWT access token.
    await storeGoogleToken(googleToken);
    await storeFinalCredentials(accessToken, studentData);

    return {'access_token': accessToken, 'student': studentData};
  }
}

@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}
