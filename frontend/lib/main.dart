import 'package:flutter/material.dart';

import 'app/app.dart';
import 'utils/settings_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialLanguage = await SettingsStorage.getOrInitUserLanguage(
    preferredLanguageCodes: WidgetsBinding.instance.platformDispatcher.locales
        .map((locale) => locale.languageCode),
  );

  runApp(GoalGetterApp(initialLocale: Locale(initialLanguage)));
}
