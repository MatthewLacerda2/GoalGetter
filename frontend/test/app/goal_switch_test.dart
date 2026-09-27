import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/features/home/presentation/screens/home_screen.dart';
import 'package:http/http.dart' as http;

import '../contract/contract_client.dart';
import '../contract/error_body.dart';
import '../features/fake_backend.dart';
import 'app_harness.dart';

/// Switching goals through the app's own route table (#220): Profile pushes
/// the goals list over the tab shell, so Home and the Tutor stay mounted
/// underneath while the student picks another goal.

/// A backend with two goals whose goal-scoped reads follow
/// `students.current_goal_id`, as the real one's do.
class _TwoGoals {
  String active = 'g1';
  final List<String> calls = [];

  static const _names = {'g1': 'Chess', 'g2': 'Italian'};

  String _goal(String id) =>
      goalJson(id, active: id == active, name: _names[id]!);

  http.Client get client => contractClient((request) async {
        final key =
            '${request.method} ${request.url.path.replaceFirst('/api/v1', '')}';
        calls.add(key);
        final setActive = RegExp(r'^PUT /goals/(\w+)/set-active$')
            .firstMatch(key);
        if (setActive != null) active = setActive.group(1)!;
        final name = _names[active];
        return switch (key) {
          'GET /goals' => http.Response('[${_goal('g1')}, ${_goal('g2')}]', 200),
          _ when setActive != null =>
            http.Response('{"goal_id": "$active"}', 200),
          'GET /home' => http.Response(
              '{"goal_name": "$name", "current_elo": 1000,'
              ' "current_streak": 0, "recent_lessons": []}',
              200,
            ),
          'GET /tutor/messages' => http.Response(
              '[{"id": "e-$active", "prompt": "Tell me about $name",'
              ' "responses": ["Sure."], "is_liked": false,'
              ' "created_at": "2026-09-21T10:00:00.000000"}]',
              200,
            ),
          _ when key.endsWith('/lessons') =>
            http.Response(errorBody(ErrorCode.lessonsNotReady), 409),
          _ => http.Response(noRoute, 599),
        };
      });
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a goal picked in Profile is the one Home, Tutor and Lesson read',
      (tester) async {
    final backend = _TwoGoals();
    final (router, _) = await launchApp(
      tester,
      backend.client,
      stored: {'access_token': 'a', 'refresh_token': 'r'},
    );
    expect(routerAt(router), AppRoutes.home);
    expect(find.text('Chess'), findsOneWidget);
    final home = tester.element(find.byType(HomeScreen));
    await _tap(tester, 'Tutor');
    expect(find.text('Tell me about Chess'), findsOneWidget);

    await _tap(tester, 'Profile');
    await _tap(tester, 'Manage goals');
    await _tap(tester, 'Italian');
    await _tap(tester, 'Set as current goal');

    expect(routerAt(router), AppRoutes.home);
    expect(
      tester.element(find.byType(HomeScreen)),
      same(home),
      reason: 'Home stayed mounted under the goals list',
    );
    expect(find.text('Italian'), findsOneWidget);
    expect(find.text('Chess'), findsNothing);

    await _tap(tester, 'Tutor');
    expect(find.text('Tell me about Italian'), findsOneWidget);
    expect(find.text('Tell me about Chess'), findsNothing);

    await _tap(tester, 'Home');
    await _tap(tester, 'Start lesson');
    expect(backend.calls, contains('POST /goals/g2/lessons'));
    expect(backend.calls, isNot(contains('POST /goals/g1/lessons')));
  });

  testWidgets('signing out asks no goal-scoped screen to load again',
      (tester) async {
    final backend = _TwoGoals();
    await launchApp(
      tester,
      backend.client,
      stored: {'access_token': 'a', 'refresh_token': 'r'},
    );
    await _tap(tester, 'Tutor');
    await _tap(tester, 'Profile');
    backend.calls.clear();

    await _tap(tester, 'Sign out');
    await _tap(tester, 'Sign out'); // the confirmation

    expect(backend.calls, ['POST /auth/logout']);
  });
}
