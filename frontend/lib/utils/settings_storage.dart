import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const String _languageKey = 'user_language';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _currentGoalIdKey = 'current_goal_id';
  static const String _currentObjectiveIdKey = 'current_objective_id';

  static const String english = 'en';
  static const String portuguese = 'pt';
  static const String french = 'fr';
  static const String spanish = 'es';
  static const String german = 'de';

  static const String defaultLanguage = english;

  static Future<String> getUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? defaultLanguage;
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

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  static Future<bool> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_isFirstLaunchKey, false);
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
