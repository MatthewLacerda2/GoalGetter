import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:goal_getter/core/services/shared_preferences_provider.dart';

part 'settings_storage.g.dart';

/// Everything the app keeps on the device, in shared_preferences: the session
/// (access token and refresh token), the active goal id, and the preferences
/// (language, notifications, theme).
///
/// Two ways out: [clearSession] when the backend refuses the session (the
/// preferences survive), and [clearAll] on sign-out, which deletes every key,
/// preferences included (decided in #51).
class SettingsStorage {
  final SharedPreferences _prefs;

  SettingsStorage(this._prefs);

  // --- Storage Keys ---
  static const String _languageKey = 'user_language';
  static const String _currentGoalIdKey = 'current_goal_id';
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _notificationsKey = 'notifications_on';
  // Keys this build never writes and nothing reads: the Google token (only
  // POST /auth/signup needs it, once) and the student's profile, left by older
  // builds. Removed with the session, so a device that holds them drops them.
  static const String _googleTokenKey = 'google_token';
  static const String _userInfoKey = 'user_info';
  static const String _themeModeKey = 'theme_mode';

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

  // --- Active Goal ---
  //
  // The device's copy of `activeGoalProvider` (core/services/active_goal.dart),
  // which is what the app reads and writes: a write here alone would leave
  // every screen on the goal before it.

  String? readCurrentGoalId() {
    return _prefs.getString(_currentGoalIdKey);
  }

  /// Stores [goalId] as the active goal; null removes it.
  Future<void> storeCurrentGoalId(String? goalId) async {
    if (goalId == null) {
      await _prefs.remove(_currentGoalIdKey);
    } else {
      await _prefs.setString(_currentGoalIdKey, goalId);
    }
  }

  // --- Auth & Token Preferences ---

  String? getAccessToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<bool> setAccessToken(String token) async {
    return await _prefs.setString(_tokenKey, token);
  }

  String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<bool> setRefreshToken(String token) async {
    return await _prefs.setString(_refreshTokenKey, token);
  }

  // --- Notifications Preference ---

  /// Off until the student turns it on.
  bool readNotificationsOn() {
    return _prefs.getBool(_notificationsKey) ?? false;
  }

  Future<bool> writeNotificationsOn({required bool on}) async {
    return await _prefs.setBool(_notificationsKey, on);
  }

  // --- Theme Preference ---

  /// Follows the phone until the student picks light or dark. Stored
  /// by the enum's name; anything unreadable falls back to the phone.
  ThemeMode readThemeMode() {
    final stored = _prefs.getString(_themeModeKey);
    return ThemeMode.values.asNameMap()[stored] ?? ThemeMode.system;
  }

  Future<bool> writeThemeMode(ThemeMode mode) =>
      _prefs.setString(_themeModeKey, mode.name);

  // --- Cleardown Methods ---

  /// Drops the session and the active goal, which belongs to that student.
  /// Language, notifications and theme stay: the device's owner has not
  /// changed.
  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_googleTokenKey);
    await _prefs.remove(_userInfoKey);
    await _prefs.remove(_currentGoalIdKey);
  }

  /// Sign-out: every key goes, preferences included.
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

@Riverpod(keepAlive: true)
SettingsStorage settingsStorage(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsStorage(prefs);
}
