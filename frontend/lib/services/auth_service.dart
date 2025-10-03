import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userInfoKey = 'user_info';
  
  // Use your Google Client ID from backend/utils/envs.py
  //google clint authorize redirect uri: https://n8n.srv894261.hstgr.cloud/rest/oauth2-credential/callback
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "1039088402014-9bv0lqhs308ld52fvgqmje260fqf8pbn.apps.googleusercontent.com", // From your backend config
    scopes: ['email', 'profile'],
  );

  // In-memory storage for OAuth data during onboarding
  String? _tempGoogleToken;
  Map<String, dynamic>? _tempUserInfo;

  // Sign in with Google and return the ID token (in memory only)
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
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

      return {
        'token': idToken,
        'user': _tempUserInfo,
      };
    } catch (error) {
      print('Error signing in with Google: $error');
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
}
