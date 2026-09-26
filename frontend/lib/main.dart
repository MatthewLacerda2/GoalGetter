import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/core/services/shared_preferences_provider.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean, path-based URLs on web (no `#` hash) for go_router.
  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();
  SettingsStorage.initialize(prefs);

  runApp(
    ProviderScope(
      retry: noAutomaticRetry,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GoalGetterApp(),
    ),
  );
}
