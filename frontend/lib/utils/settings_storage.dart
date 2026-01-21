import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const String _languageKey = 'user_language';
  static const String _currentGoalIdKey = 'current_goal_id';
  static const String _currentObjectiveIdKey = 'current_objective_id';

  static const String english = 'en';
  static const String portuguese = 'pt';
  static const String french = 'fr';
  static const String spanish = 'es';
  static const String german = 'de';

  /// Default whenever we cannot match the device language.
  static const String defaultLanguage = portuguese;

  static String _normalizeLanguageCode(String language) {
    // Defensive normalization in case we ever receive values like "en-US" / "pt_BR".
    final normalized = language.trim().toLowerCase();
    final separatorIndex = normalized.indexOf(RegExp(r'[-_]'));
    return separatorIndex == -1
        ? normalized
        : normalized.substring(0, separatorIndex);
  }

  /// Picks the best supported language from a list of preferred device language codes.
  /// Falls back to [defaultLanguage] when no match is found.
  static String pickBestSupportedLanguage(
    Iterable<String> preferredLanguageCodes,
  ) {
    for (final code in preferredLanguageCodes) {
      final normalized = _normalizeLanguageCode(code);
      if (isSupportedLanguage(normalized)) return normalized;
    }
    return defaultLanguage;
  }

  static Future<String> getUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_languageKey);
    if (stored != null && isSupportedLanguage(stored)) return stored;
    return defaultLanguage;
  }

  /// Returns the stored language (if any) without falling back.
  static Future<String?> getStoredUserLanguageOrNull() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_languageKey);
    if (stored == null) return null;
    return isSupportedLanguage(stored) ? stored : null;
  }

  /// Ensures a language is stored for newcomers (first launch / before login).
  ///
  /// - If a supported language is already stored, it is returned.
  /// - Otherwise, it selects the best match from [preferredLanguageCodes] and stores it.
  /// - If no match is found, it stores and returns [defaultLanguage] (Portuguese).
  static Future<String> getOrInitUserLanguage({
    required Iterable<String> preferredLanguageCodes,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getString(_languageKey);
    if (stored != null && isSupportedLanguage(stored)) return stored;

    final selected = pickBestSupportedLanguage(preferredLanguageCodes);
    await prefs.setString(_languageKey, selected);
    return selected;
  }

  static Future<bool> setUserLanguage(String language) async {
    if (!isSupportedLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }

    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_languageKey, language);
  }

  static bool isSupportedLanguage(String language) {
    return language == english ||
        language == portuguese ||
        language == french ||
        language == spanish ||
        language == german;
  }

  static Future<String?> getCurrentGoalId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentGoalIdKey);
  }

  static Future<bool> setCurrentGoalId(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_currentGoalIdKey, goalId);
  }

  static Future<String?> getCurrentObjectiveId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentObjectiveIdKey);
  }

  static Future<bool> setCurrentObjectiveId(String objectiveId) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_currentObjectiveIdKey, objectiveId);
  }

  static Future<void> clearCurrentGoalAndObjective() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentGoalIdKey);
    await prefs.remove(_currentObjectiveIdKey);
  }

  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentGoalIdKey);
    await prefs.remove(_currentObjectiveIdKey);
    // Note: Language preference is kept, but other user data is cleared
  }
}
