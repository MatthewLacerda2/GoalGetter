import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/locale_provider.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/start_screen.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import '../fake_backend.dart';

/// The start screen's language selector (#172): it starts at the device's
/// language, and picking another changes the app at once.

/// Google that never signs anyone in: these tests only read the selector.
class _IdleGoogle extends AuthService {
  _IdleGoogle({required super.api, required super.storage});

  @override
  Future<void> ensureInitialized() async {}

  @override
  Stream<String> googleTokens() => const Stream.empty();
}

/// A first launch (nothing stored) on a device whose language list is
/// [device], with the app's locale bound to [localeProvider] as in `app.dart`.
Future<FakeBackend> pumpFirstLaunch(
  WidgetTester tester,
  List<Locale> device,
) async {
  tester.platformDispatcher.localesTestValue = device;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final backend = FakeBackend({});
  await backend.start({'access_token': ''});
  await tester.pumpWidget(ProviderScope(
    retry: noAutomaticRetry,
    overrides: [
      ...backend.overrides,
      authServiceProvider.overrideWithValue(
        _IdleGoogle(api: backend.api, storage: backend.storage),
      ),
    ],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp(
        locale: ref.watch(localeProvider),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StartScreen(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return backend;
}

void main() {
  testWidgets('the selector starts at the device language', (tester) async {
    final backend = await pumpFirstLaunch(
      tester,
      const [Locale('de', 'DE'), Locale('en', 'US')],
    );

    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Ohne Anmeldung ausprobieren'), findsOneWidget);
    expect(backend.storage.readUserLanguageSync(), SettingsStorage.german);
  });

  testWidgets('an unsupported first language falls to the next supported one',
      (tester) async {
    await pumpFirstLaunch(tester, const [Locale('ja'), Locale('fr', 'CA')]);

    expect(find.text('Français'), findsOneWidget);
  });

  testWidgets('an English-first browser, Portuguese picked: the app changes',
      (tester) async {
    final backend = await pumpFirstLaunch(
      tester,
      const [Locale('en', 'US'), Locale('pt', 'BR')],
    );
    expect(find.text('Try it without signing in'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();

    expect(find.text('Experimentar sem entrar'), findsOneWidget);
    expect(find.text('Português'), findsOneWidget);
    expect(backend.storage.readUserLanguageSync(), SettingsStorage.portuguese);
  });
}
