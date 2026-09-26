import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/app/router/app_router.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/profile/presentation/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/api_fake.dart';
import '../features/profile/profile_screen_test.dart' show meJson;

/// The real [GoalGetterApp], routed straight to the profile page, over a
/// device whose stored preferences are [stored].
Future<SharedPreferences> pumpApp(
  WidgetTester tester, {
  Map<String, String> stored = const {},
}) async {
  final fake = ApiFake({
    'GET /me': [(200, meJson)],
    'GET /goals': [(200, '[]')],
  });
  final overrides = await fake.overrides();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_language', 'en');
  for (final entry in stored.entries) {
    await prefs.setString(entry.key, entry.value);
  }
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => ProfileScreen())],
  );
  await tester.pumpWidget(ProviderScope(
    retry: noAutomaticRetry,
    overrides: [...overrides, goRouterProvider.overrideWithValue(router)],
    child: const GoalGetterApp(),
  ));
  await tester.pumpAndSettle();
  return prefs;
}

Brightness brightnessOn(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(ProfileScreen))).brightness;

Future<void> choose(WidgetTester tester, String option) async {
  await tester.tap(find.text('Theme'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new visitor follows the phone', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);

    expect(find.text('Follow the phone'), findsOneWidget);
    expect(brightnessOn(tester), Brightness.dark);
  });

  testWidgets('picking dark repaints at once and is stored', (tester) async {
    final prefs = await pumpApp(tester);
    expect(brightnessOn(tester), Brightness.light);

    await choose(tester, 'Dark');

    expect(brightnessOn(tester), Brightness.dark);
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testWidgets('the stored choice is read back at start', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester, stored: {'theme_mode': 'light'});

    expect(find.text('Light'), findsOneWidget);
    expect(brightnessOn(tester), Brightness.light);
  });

  test('an unreadable stored value falls back to the phone', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    final storage = SettingsStorage(await SharedPreferences.getInstance());

    expect(storage.readThemeMode(), ThemeMode.system);
  });
}
