import 'package:shared_preferences/shared_preferences.dart';

class SettingsStorage {
  static const String _languageKey = 'user_language';
  
  // Supported languages
  static const String english = 'en';
  static const String portuguese = 'pt';
  
  // Default language
  static const String defaultLanguage = english;
  
  // Get the current user language
  static Future<String> getUserLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? defaultLanguage;
  }
  
  // Set the user language
  static Future<bool> setUserLanguage(String language) async {
    // Validate that the language is supported
    if (!isSupportedLanguage(language)) {
      throw ArgumentError('Unsupported language: $language');
    }
    
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_languageKey, language);
  }
  
  // Check if a language is supported
  static bool isSupportedLanguage(String language) {
    return language == english || language == portuguese;
  }
  
  // Get list of supported languages
  static List<String> getSupportedLanguages() {
    return [english, portuguese];
  }
  
  // Get display name for a language
  static String getLanguageDisplayName(String language) {
    switch (language) {
      case english:
        return 'English';
      case portuguese:
        return 'Português';
      default:
        return 'Unknown';
    }
  }
  
  // Reset to default language
  static Future<bool> resetToDefaultLanguage() async {
    return await setUserLanguage(defaultLanguage);
  }
  
  // Clear all settings (useful for testing or logout)
  static Future<bool> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_languageKey);
  }
}