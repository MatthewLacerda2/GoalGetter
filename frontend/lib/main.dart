import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/core/services/shared_preferences_provider.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  SettingsStorage.initialize(prefs);

  final initialLanguage = await SettingsStorage.getOrInitUserLanguage(
    preferredLanguageCodes: WidgetsBinding.instance.platformDispatcher.locales
        .map((locale) => locale.languageCode),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: GoalGetterApp(initialLocale: Locale(initialLanguage)),
    ),
  );
}
