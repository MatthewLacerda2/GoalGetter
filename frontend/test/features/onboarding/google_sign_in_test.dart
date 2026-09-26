import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/router/app_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/study_plan.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import '../fake_backend.dart';
import 'fake_onboarding_api.dart';

/// The start screen, on the app's own route table, with Google's side of the
/// sign-in faked — that half needs a real Google account and a browser, so
/// what these tests hold is everything after it: the token arrives, and the
/// app turns it into a session and goes somewhere sensible (#84).

/// Google, as far as the button can tell.
///
/// Only the two members that talk to the GIS SDK are replaced, so the token
/// still travels through the real `signupWithGoogle` and the real storage.
class FakeGoogle extends AuthService {
  FakeGoogle({required super.api, required super.storage});

  /// Broadcast, like `GoogleSignIn.authenticationEvents`: a button that
  /// never got as far as listening still lets the controller close.
  final StreamController<String> tokens =
      StreamController<String>.broadcast();

  /// The SDK cannot be loaded (no network, a blocked script, no plugin).
  bool sdkIsBroken = false;

  /// Google's own sheet refuses to open.
  bool signInIsBroken = false;

  int sheetsOpened = 0;

  @override
  Future<void> ensureInitialized() async {
    if (sdkIsBroken) throw StateError('the GIS SDK did not load');
  }

  @override
  Stream<String> googleTokens() => tokens.stream;

  @override
  Future<void> startGoogleSignIn() async {
    sheetsOpened++;
    if (signInIsBroken) throw StateError('Google would not open');
  }
}

/// What POST /auth/signup answers: the session the app then runs on.
const _session = '{"access_token": "fresh", "refresh_token": "r2",'
    ' "student": {"name": "Ada"}}';

final _routesProvider = Provider<List<RouteBase>>(appRoutes);

String _at(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

/// The start screen of a build with no session, over a backend that answers
/// [signup] to POST /auth/signup and hands [goals] to GET /goals.
///
/// [held] is the draft the student was committing when he was sent here.
Future<(GoRouter, FakeGoogle, SettingsStorage)> pumpStart(
  WidgetTester tester, {
  Reply signup = (200, _session),
  Reply goals = (200, '[]'),
  GoalDraft? held,
  bool googleIsBroken = false,
}) async {
  final backend = FakeBackend({
    'POST /auth/signup': [signup],
    'GET /goals': [goals],
  });
  // FakeBackend stores a token by default; a visitor about to sign in has
  // none, which is what sends him to this screen in the first place.
  await backend.start({'access_token': ''});
  final google = FakeGoogle(api: backend.api, storage: backend.storage)
    ..sdkIsBroken = googleIsBroken
    ..signInIsBroken = googleIsBroken;
  addTearDown(google.tokens.close);
  final container = ProviderContainer(overrides: [
    ...backend.overrides,
    authServiceProvider.overrideWithValue(google),
  ]);
  addTearDown(container.dispose);
  if (held != null) {
    container.read(pendingGoalDraftProvider.notifier).hold(held);
  }
  final router = GoRouter(
    initialLocation: AppRoutes.start,
    routes: container.read(_routesProvider),
  );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
  return (router, google, backend.storage);
}

/// Google says yes: the token the button would have been handed.
Future<void> googleSignsIn(WidgetTester tester, FakeGoogle google) async {
  google.tokens.add('google-id-token');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a sign-in becomes a session and leaves the screen', (
    tester,
  ) async {
    final (router, google, storage) = await pumpStart(tester);

    await googleSignsIn(tester, google);

    expect(storage.getAccessToken(), 'fresh');
    expect(storage.getRefreshToken(), 'r2');
    // No goals yet, so the new student lands on goal creation.
    expect(_at(router), AppRoutes.goalPrompt);
  });

  testWidgets('from a goal draft, it comes back to that draft', (tester) async {
    final (router, google, storage) = await pumpStart(tester, held: draft);

    await googleSignsIn(tester, google);

    expect(storage.getAccessToken(), 'fresh');
    expect(_at(router), AppRoutes.studyPlan);
    final screen = tester.widget<StudyPlanScreen>(find.byType(StudyPlanScreen));
    expect(screen.draft, same(draft));
  });

  testWidgets('a draft outlives a failed exchange and is still there', (
    tester,
  ) async {
    final (router, google, storage) = await pumpStart(
      tester,
      signup: (503, '{"detail": "The model is overloaded"}'),
      held: draft,
    );

    await googleSignsIn(tester, google);

    expect(find.text('Could not sign in'), findsOneWidget);
    expect(find.text('The model is overloaded'), findsOneWidget);
    expect(storage.getAccessToken(), isEmpty);
    expect(_at(router), AppRoutes.start);
  });

  testWidgets('Google refusing is said on the screen it happened on', (
    tester,
  ) async {
    final (router, google, _) = await pumpStart(tester);

    google.tokens.addError(StateError('popup_closed'));
    await tester.pumpAndSettle();

    expect(find.text('Could not sign in'), findsOneWidget);
    expect(_at(router), AppRoutes.start);
  });

  // Off the web the app draws the button and a tap is what opens Google.
  testWidgets('pressing the button opens Google', (tester) async {
    final (_, google, _) = await pumpStart(tester);

    await tester.tap(find.text('Start with Google'));
    await tester.pumpAndSettle();

    expect(google.sheetsOpened, 1);
  });

  // An SDK that never loaded leaves a button that cannot work. It stays
  // pressable on purpose: a dead spinner explains nothing.
  testWidgets('a button that cannot sign anyone in says so when pressed', (
    tester,
  ) async {
    final (router, google, _) = await pumpStart(tester, googleIsBroken: true);

    await tester.tap(find.text('Start with Google'));
    await tester.pumpAndSettle();

    expect(google.sheetsOpened, 1);
    expect(find.text('Could not sign in'), findsOneWidget);
    expect(_at(router), AppRoutes.start);
  });

  testWidgets('the public first steps are reachable with no account', (
    tester,
  ) async {
    final (router, _, _) = await pumpStart(tester);

    await tester.tap(find.text('Try it without signing in'));
    await tester.pumpAndSettle();

    expect(_at(router), AppRoutes.goalPrompt);
  });
}
