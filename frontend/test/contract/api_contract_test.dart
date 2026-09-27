import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_route.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import 'openapi_snapshot.dart';
import 'schema_check.dart';

/// The app against the backend's committed API (`backend/openapi.json`,
/// written by `make back-build`, #213). Every call the app can make is an
/// [ApiRoute]; every fixture a fake backend serves is checked where it is
/// served (`contract_client.dart`). This file checks the routes, and that the
/// fixture check itself catches what it is for.
void main() {
  group('every route the app calls is served by the backend', () {
    for (final route in ApiRoute.values.where((r) => !r.devOnly)) {
      test('${route.method} ${route.template}', () {
        expect(openApi.operation(route), isNotNull,
            reason: 'backend/openapi.json has no ${route.method} '
                '${route.template}: the backend renamed or removed it');
      });
    }
  });

  test('a dev-only route is the one production hides', () {
    // Hidden from the schema when DEV_LOGIN is off, which the snapshot pins.
    // Were it ever in the snapshot, it would be a production route, and
    // `devOnly` would be keeping it from being checked.
    for (final route in ApiRoute.values.where((r) => r.devOnly)) {
      expect(openApi.operation(route), isNull, reason: route.name);
    }
  });

  test('every route is found again from the paths it fills', () {
    for (final route in ApiRoute.values) {
      final filled = route.path({for (final p in route.params) p: 'x1'});
      expect(OpenApiSnapshot.routeOf(route.method, filled), route);
    }
  });

  test("the backend's error codes are the app's", () {
    // #214: the app decides on these, so one it lacks would be said as a
    // generic failure, and one it invents would never arrive.
    expect(
      openApi.schemaEnum('ErrorCode'),
      unorderedEquals(ErrorCode.values.map((c) => c.wire)),
    );
  });

  test("the backend's languages are the app's locales", () {
    // A string enum mirrored on both sides, checked the way any later one is.
    expect(
      openApi.schemaEnum('Language'),
      unorderedEquals(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
      ),
    );
  });

  group('a fixture the backend could not have sent is caught', () {
    const goal = '{"id": "g1", "name": "Go", "description": "d",'
        ' "current_elo": 1000, "is_active": true,'
        ' "created_at": "2026-09-01T10:00:00Z",'
        ' "updated_at": "2026-09-01T10:00:00Z"}';

    List<String> goalsReply(String body, {int status = 200}) =>
        openApi.replyErrors(ApiRoute.listGoals, status, body);

    test('what the backend sends passes', () {
      expect(goalsReply('[$goal]'), isEmpty);
    });

    test('a renamed field', () {
      final renamed = goal.replaceFirst('"current_elo"', '"elo"');
      expect(goalsReply('[$renamed]'), [
        r'$[0]: missing "current_elo"',
        r'$[0]: "elo" is not a field of this response',
      ]);
    });

    test('a wrong type, and a date that is not one', () {
      final wrong = goal
          .replaceFirst('"is_active": true', '"is_active": "yes"')
          .replaceFirst('"2026-09-01T10:00:00Z"', '"yesterday"');
      expect(goalsReply('[$wrong]'), [
        r'$[0].is_active: expected boolean, got "yes"',
        r'$[0].created_at: "yesterday" is not a date-time',
      ]);
    });

    test('a success status the route never answers', () {
      expect(
        openApi.replyErrors(ApiRoute.createGoal, 200, '{}'),
        ['POST /goals never answers 200; it answers 201, 4XX, 5XX'],
      );
    });

    test('an error body without its code', () {
      const known = '{"code": "no_active_goal", "detail": "x"}';
      expect(goalsReply(known, status: 404), isEmpty);
      expect(goalsReply('{"detail": "Goal not found"}', status: 404),
          [r'$: missing "code"']);
      expect(goalsReply('{"code": "goal_gone", "detail": "x"}', status: 503),
          [contains('"goal_gone" is not one of')]);
    });

    test('a schema keyword the check does not know fails, never passes', () {
      expect(
        schemaErrors(1, {'oneOf': <Object>[]}, (_) => {}),
        [contains('does not know yet')],
      );
    });
  });
}
