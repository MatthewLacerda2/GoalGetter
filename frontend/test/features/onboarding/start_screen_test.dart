import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/theme/app_palette.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/locale_provider.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/start_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/dev_login_button.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/google_sign_in_button.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import '../fake_backend.dart';

/// The start page of #180: what it says, that it wears the app's own theme in
/// both modes, and that everything a visitor could do on the old page he can
/// still do on this one. Every test runs once in the light theme and once in
/// the dark.

final _modes = ValueVariant<ThemeMode>({ThemeMode.light, ThemeMode.dark});

/// Google, as far as the page can tell: it records presses instead of
/// opening a sheet, and signs in as the fictitious student without a network.
class _RecordingAuth extends AuthService {
  _RecordingAuth({required super.api, required super.storage});

  int sheetsOpened = 0;
  final List<String> fictitious = [];

  @override
  Future<void> ensureInitialized() async {}

  @override
  Stream<String> googleTokens() => const Stream.empty();

  @override
  Future<void> startGoogleSignIn() async => sheetsOpened++;

  @override
  Future<void> signInAsFictitious(String name) async => fictitious.add(name);
}

/// A first launch in English on a phone, with the start page at /start and
/// a placeholder at every route it can send the visitor to.
Future<_RecordingAuth> _pumpStart(
  WidgetTester tester, {
  bool devLogin = false,
  Size phone = const Size(390, 844),
}) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final backend = FakeBackend({});
  await backend.start({'access_token': ''});
  final auth = _RecordingAuth(api: backend.api, storage: backend.storage);
  final router = GoRouter(initialLocation: AppRoutes.start, routes: [
    GoRoute(
      path: AppRoutes.start,
      builder: (_, __) => StartScreen(devLogin: devLogin),
    ),
    for (final path in [AppRoutes.goalPrompt, AppRoutes.home])
      GoRoute(path: path, builder: (_, __) => Text('landed $path')),
  ]);
  await tester.pumpWidget(ProviderScope(
    retry: noAutomaticRetry,
    overrides: [
      ...backend.overrides,
      authServiceProvider.overrideWithValue(auth),
    ],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _modes.currentValue,
        locale: ref.watch(localeProvider),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return auth;
}

void main() {
  testWidgets('it says what the app is, and nothing of courses',
      (tester) async {
    await _pumpStart(tester);

    expect(find.byType(Image), findsOneWidget);
    for (final line in [
      'Learn whatever you want',
      'Tailor-made teaching',
      'Any subject you name',
      'Two minutes a day',
      'Always at your level',
      'A tutor to ask anything',
    ]) {
      expect(find.text(line), findsOneWidget);
    }
    final words = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data?.toLowerCase() ?? '');
    expect(words.where((w) => w.contains('course')), isEmpty);
  }, variant: _modes);

  testWidgets('it wears the theme of the mode the app is in', (tester) async {
    await _pumpStart(tester);

    final palette = _modes.currentValue == ThemeMode.dark
        ? AppPalette.dark
        : AppPalette.light;
    final scaffold = tester.element(find.byType(Scaffold));
    expect(Theme.of(scaffold).colorScheme.surface, palette.surface);
  }, variant: _modes);

  testWidgets('Google sign-in is there, and pressing it asks Google',
      (tester) async {
    final auth = await _pumpStart(tester);

    expect(find.byType(DevLoginButton), findsNothing);
    await tester.tap(find.text('Start with Google'));
    await tester.pumpAndSettle();

    expect(auth.sheetsOpened, 1);
  }, variant: _modes);

  testWidgets('trying it without signing in opens goal creation',
      (tester) async {
    await _pumpStart(tester);

    await tester.tap(find.text('Try it without signing in'));
    await tester.pumpAndSettle();

    expect(find.text('landed ${AppRoutes.goalPrompt}'), findsOneWidget);
  }, variant: _modes);

  testWidgets('picking a language changes the page at once', (tester) async {
    await _pumpStart(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();

    expect(find.text('Aprenda o que quiser'), findsOneWidget);
    expect(find.text('Experimentar sem entrar'), findsOneWidget);
  }, variant: _modes);

  testWidgets('a DEV_LOGIN build signs in as the fictitious student instead',
      (tester) async {
    final auth = await _pumpStart(tester, devLogin: true);

    expect(find.byType(GoogleSignInButton), findsNothing);
    await tester.tap(find.byType(DevLoginButton));
    await tester.pump();

    expect(auth.fictitious, ['Claude']);
  }, variant: _modes);

  testWidgets('the terms are stated under the ways in', (tester) async {
    await _pumpStart(tester);

    expect(
      find.text(
        'By continuing, you agree to our Terms of Service and Privacy Policy',
      ),
      findsOneWidget,
    );
  }, variant: _modes);

  testWidgets('a short phone scrolls to the buttons instead of overflowing',
      (tester) async {
    await _pumpStart(tester, phone: const Size(320, 480));

    await tester.scrollUntilVisible(
      find.text('Try it without signing in'),
      100,
    );
    await tester.tap(find.text('Try it without signing in'));
    await tester.pumpAndSettle();

    expect(find.text('landed ${AppRoutes.goalPrompt}'), findsOneWidget);
  }, variant: _modes);
}
