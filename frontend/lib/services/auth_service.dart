import 'dart:convert';
import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'access_token';
  static const String _userInfoKey = 'user_info';
  static const String _googleTokenKey = 'google_token';
  
  // Web-specific configuration
  static const String _webClientId = "205743657377-gg1iilbm7fcq4q1o7smi7c10bdhlnco0.apps.googleusercontent.com";
  
  GoogleSignIn get _googleSignIn {
    if (kIsWeb) {
      // For web, use the web client ID with openid scope to get ID token
      return GoogleSignIn(
        clientId: _webClientId,
        scopes: ['email', 'profile', 'openid'], // Add 'openid' scope
      );
    } else {
      // For mobile (if you add it later), use mobile client ID
      return GoogleSignIn(
        clientId: _webClientId, // You'll change this later for mobile
        scopes: ['email', 'profile', 'openid'], // Add 'openid' scope here too
      );
    }
  }

  // In-memory storage for OAuth data during onboarding
  String? _tempGoogleToken;
  Map<String, dynamic>? _tempUserInfo;

  // Sign in with Google and return the ID token (in memory only)
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    developer.log("EA SPORTS, its in the game");
    try {
      developer.log('Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        developer.log('User cancelled sign-in');
        return null; // User cancelled the sign-in
      }

      developer.log('Google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      developer.log('ID Token: ${googleAuth.idToken != null ? "Present" : "NULL"}');
      developer.log('Access Token: ${googleAuth.accessToken != null ? "Present" : "NULL"}');
      developer.log('Full auth object: $googleAuth');

      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        developer.log('ID Token is null, throwing exception');
        throw Exception('Failed to get ID token from Google');
      }

      // Store temporarily in memory only (not persisted)
      _tempGoogleToken = idToken;
      
      _tempUserInfo = {
        'sub': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'picture': googleUser.photoUrl,
      };

      developer.log('Successfully authenticated user: ${googleUser.email}');
      return {
        'token': idToken,
        'user': _tempUserInfo,
      };
    } catch (error) {
      developer.log('Error signing in to your app with Google: $error');
      rethrow;
    }
  }

  // Add this method for web-only authentication
  Future<Map<String, dynamic>?> signInWithGoogleWeb() async {
    if (!kIsWeb) {
      throw Exception('This method is only for web');
    }
    
    try {
      developer.log('Starting Google Sign-In for web...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        developer.log('User cancelled sign-in');
        return null;
      }

      developer.log('Google user: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      developer.log('ID Token: ${googleAuth.idToken != null ? "Present" : "NULL"}');
      developer.log('Access Token: ${googleAuth.accessToken != null ? "Present" : "NULL"}');

      final String? idToken = googleAuth.idToken;
      
     if (idToken == null) {
        // For web, if ID token is null, try using access token
        final String? accessToken = googleAuth.accessToken;
        if (accessToken == null) {
          throw Exception('Failed to get any token from Google');
        }
        
        // Store access token temporarily and persistently
        _tempGoogleToken = accessToken;
        await storeGoogleToken(accessToken);
      } else {
        // Store ID token temporarily and persistently
        _tempGoogleToken = idToken;
        await storeGoogleToken(idToken);
      }
      
      _tempUserInfo = {
        'sub': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'picture': googleUser.photoUrl,
      };

      developer.log('Successfully authenticated user: ${googleUser.email}');
      return {
        'token': _tempGoogleToken,
        'user': _tempUserInfo,
      };
    } catch (error) {
      developer.log('Error signing in to your app with Google: $error');
      rethrow;
    }
  }

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
  Future<void> storeFinalCredentials(String accessToken, Map<String, dynamic> userInfo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_userInfoKey, jsonEncode(userInfo));
    
    // Clear temporary data
    _tempGoogleToken = null;
    _tempUserInfo = null;
  }

  // Get stored access token (after onboarding completion)
  Future<String?> getStoredAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user info (after onboarding completion)
  Future<Map<String, dynamic>?> getStoredUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoString = prefs.getString(_userInfoKey);
    
    if (userInfoString != null) {
      return jsonDecode(userInfoString);
    }
    return null;
  }

  // Check if user has completed onboarding and is signed in
  Future<bool> isSignedIn() async {
    final token = await getStoredAccessToken();
    return token != null && token.isNotEmpty;
  }

  // Sign out (clear both memory and storage)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userInfoKey);
    
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleTokenKey, token);
  }

  // Get stored Google token from SharedPreferences
  Future<String?> getStoredGoogleToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleTokenKey);
  }
}
