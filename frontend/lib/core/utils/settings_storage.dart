import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:goal_getter/core/services/shared_preferences_provider.dart';

part 'settings_storage.g.dart';

class SettingsStorage {
  final SharedPreferences _prefs;

  SettingsStorage(this._prefs);

  static SettingsStorage? _instance;

  /// Initialize SettingsStorage with pre-loaded SharedPreferences
  static void initialize(SharedPreferences prefs) {
    _instance = SettingsStorage(prefs);
  }

  /// Singleton instance for static contexts (e.g. legacy/static calls)
  static SettingsStorage get instance {
    if (_instance == null) {
      throw StateError('SettingsStorage has not been initialized. Call SettingsStorage.initialize(prefs) first.');
    }
    return _instance!;
  }

  // --- Storage Keys ---
  static const String _languageKey = 'user_language';
  static const String _currentGoalIdKey = 'current_goal_id';
  static const String _tokenKey = 'access_token';
  static const String _googleTokenKey = 'google_token';
  static const String _userInfoKey = 'user_info';

  // --- Supported Languages ---
  static const String english = 'en';
  static const String portuguese = 'pt';
  static const String french = 'fr';
  static const String spanish = 'es';
  static const String german = 'de';

  /// Default whenever we cannot match the device language.
  static const String defaultLanguage = portuguese;

  static String _normalizeLanguageCode(String language) {
    final normalized = language.trim().toLowerCase();
    final separatorIndex = normalized.indexOf(RegExp(r'[-_]'));
    return separatorIndex == -1
        ? normalized
        : normalized.substring(0, separatorIndex);
  }

  static bool isSupportedLanguage(String language) {
    return language == english ||
        language == portuguese ||
        language == french ||
        language == spanish ||
        language == german;
  }

  // ================= INSTANCE METHODS =================

  // --- Language Preferences ---

  String pickBestSupportedLanguage(Iterable<String> preferredLanguageCodes) {
    for (final code in preferredLanguageCodes) {
      final normalized = _normalizeLanguageCode(code);
      if (isSupportedLanguage(normalized)) return normalized;
    }
    return defaultLanguage;
  }

  String readUserLanguageSync() {
    final stored = _prefs.getString(_languageKey);
    if (stored != null && isSupportedLanguage(stored)) return stored;
    return defaultLanguage;
  }

  String? readStoredUserLanguageOrNull() {
    final stored = _prefs.getString(_languageKey);
    if (stored == null) return null;
    return isSupportedLanguage(stored) ? stored : null;
  }

  String initUserLanguage({required Iterable<String> preferredLanguageCodes}) {
    final stored = _prefs.getString(_languageKey);
    if (stored != null && isSupportedLanguage(stored)) return stored;

    final selected = pickBestSupportedLanguage(preferredLanguageCodes);
    _prefs.setString(_languageKey, selected);
    return selected;
  }

  Future<bool> writeUserLanguage(String language) async {
    if (!isSupportedLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }
    return await _prefs.setString(_languageKey, language);
  }

  // --- Goal Preferences ---

  String? readCurrentGoalId() {
    return _prefs.getString(_currentGoalIdKey);
  }

  Future<bool> writeCurrentGoalId(String goalId) async {
    return await _prefs.setString(_currentGoalIdKey, goalId);
  }

  Future<bool> deleteCurrentGoal() async {
    return await _prefs.remove(_currentGoalIdKey);
  }

  // --- Auth & Token Preferences ---

  String? getAccessToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<bool> setAccessToken(String token) async {
    return await _prefs.setString(_tokenKey, token);
  }

  String? getGoogleToken() {
    return _prefs.getString(_googleTokenKey);
  }

  Future<bool> setGoogleToken(String token) async {
    return await _prefs.setString(_googleTokenKey, token);
  }

  Map<String, dynamic>? getUserInfo() {
    final userInfoString = _prefs.getString(_userInfoKey);
    if (userInfoString != null) {
      try {
        return jsonDecode(userInfoString) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<bool> setUserInfo(Map<String, dynamic> userInfo) async {
    return await _prefs.setString(_userInfoKey, jsonEncode(userInfo));
  }

  // --- Cleardown Methods ---

  Future<void> clearAuthData() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_googleTokenKey);
    await _prefs.remove(_userInfoKey);
  }

  Future<void> deleteAllUserData() async {
    await clearAuthData();
    await _prefs.remove(_currentGoalIdKey);
  }

  // ================= STATIC BACKWARD COMPATIBILITY WRAPPERS =================

  static String getUserLanguageSync() => instance.readUserLanguageSync();

  static Future<String> getUserLanguage() => Future.value(instance.readUserLanguageSync());

  static Future<String?> getStoredUserLanguageOrNull() => Future.value(instance.readStoredUserLanguageOrNull());

  static Future<String> getOrInitUserLanguage({required Iterable<String> preferredLanguageCodes}) =>
      Future.value(instance.initUserLanguage(preferredLanguageCodes: preferredLanguageCodes));

  static Future<bool> setUserLanguage(String language) => instance.writeUserLanguage(language);

  static Future<String?> getCurrentGoalId() => Future.value(instance.readCurrentGoalId());

  static Future<bool> setCurrentGoalId(String goalId) => instance.writeCurrentGoalId(goalId);

  static Future<void> clearCurrentGoal() => instance.deleteCurrentGoal();

  static Future<void> clearAllUserData() => instance.deleteAllUserData();
}

@riverpod
SettingsStorage settingsStorage(SettingsStorageRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsStorage(prefs);
}
