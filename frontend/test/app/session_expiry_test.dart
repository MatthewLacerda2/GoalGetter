import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/start_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../contract/contract_client.dart';
import '../contract/error_body.dart';
import '../features/fake_backend.dart';
import 'app_harness.dart';

/// Session expiry through the app's own router (#224): the API client only
/// clears the session, and the router's redirect is what moves the student.
/// Everything but the network and Google is the real app.

final _activeGoal = '[${goalJson('g1', active: true, name: 'Chess')}]';

const _home = '{"goal_name": "Chess", "current_elo": 1000,'
    ' "current_streak": 0, "recent_lessons": []}';

final _expired = errorBody(ErrorCode.invalidToken);

/// A backend where GET /goals knows the student, GET /home answers
/// [homeStatus] (401: his access token expired), POST /goals says the token
/// expired, and POST /auth/refresh answers [refreshStatus].
http.Client _backend(int refreshStatus, int homeStatus) =>
    contractClient((request) async {
      final path = request.url.path.replaceFirst('/api/v1', '');
      return switch ('${request.method} $path') {
        'GET /goals' => http.Response(_activeGoal, 200),
        'GET /home' => homeStatus == 200
            ? http.Response(_home, 200)
            : http.Response(_expired, homeStatus),
        'POST /goals' => http.Response(_expired, 401),
        'POST /auth/refresh' => http.Response(
            errorBody(ErrorCode.invalidRefreshToken),
            refreshStatus,
          ),
        _ => http.Response(noRoute, 599),
      };
    });

/// Launches the real app over [stored] and lets it settle.
Future<(GoRouter, SharedPreferences)> _launch(
  WidgetTester tester, {
  Map<String, Object> stored = const {},
  int refreshStatus = 401,
  int homeStatus = 401,
}) =>
    launchApp(tester, _backend(refreshStatus, homeStatus), stored: stored);

String _at(GoRouter router) => routerAt(router);

const _session = {'access_token': 'expired-access', 'refresh_token': 'r1'};

void main() {
  testWidgets('an expired session whose refresh is refused lands on start',
      (tester) async {
    final (router, prefs) = await _launch(tester, stored: _session);

    expect(_at(router), AppRoutes.start);
    expect(find.byType(StartScreen), findsOneWidget);
    expect(prefs.getString('access_token'), isNull);
    expect(prefs.getString('user_language'), 'en',
        reason: 'an expired session is not a sign-out: preferences stay');
  });

  testWidgets('a refresh the server fails keeps the student at home',
      (tester) async {
    final (router, prefs) =
        await _launch(tester, stored: _session, refreshStatus: 503);

    expect(_at(router), AppRoutes.home);
    expect(prefs.getString('refresh_token'), 'r1');
  });

  testWidgets('a visitor opening a signed-in path lands on start',
      (tester) async {
    final (router, _) = await _launch(tester);
    expect(_at(router), AppRoutes.start);

    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(_at(router), AppRoutes.start);

    router.go(AppRoutes.goalPrompt);
    await tester.pumpAndSettle();
    expect(_at(router), AppRoutes.goalPrompt,
        reason: 'goal creation up to the plan needs no session');
  });

  testWidgets('the splash decides again on every visit', (tester) async {
    final (router, _) =
        await _launch(tester, stored: _session, homeStatus: 200);
    expect(_at(router), AppRoutes.home);

    router.go(AppRoutes.splash);
    await tester.pumpAndSettle();

    expect(_at(router), AppRoutes.home);
  });

  testWidgets('a session that ends on the plan goes to sign in, draft held',
      (tester) async {
    final (router, _) =
        await _launch(tester, stored: _session, homeStatus: 200);
    expect(_at(router), AppRoutes.home);
    const draft = GoalDraft(
      prompt: 'Learn chess',
      answers: [],
      plan: StudyPlan(goalName: 'Chess', description: 'Openings.'),
    );

    router.go(AppRoutes.studyPlan, extra: draft);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    expect(_at(router), AppRoutes.start);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(GoalGetterApp)));
    expect(container.read(pendingGoalDraftProvider), draft);
  });
}
