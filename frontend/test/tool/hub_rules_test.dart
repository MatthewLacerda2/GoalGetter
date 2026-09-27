import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// The rules of `tool/hub_rules.dart` (#231): each kind fails outside its hub
/// and passes inside it. The cases read what the code does — the import, the
/// type, the constructor — so a renamed class is the same finding.

List<String> _rules(String path, String source) =>
    lintSource(path, source).map((v) => v.rule).toList();

const _controller =
    'lib/features/home/presentation/controllers/home_controller.dart';

/// rule -> (its home, the code outside it)
const Map<String, (String, String)> _outsideItsHub = {
  'http-outside-api': (
    'lib/core/api/api_client.dart',
    "import 'package:http/http.dart' as http;",
  ),
  'api-outside-data': (
    'lib/features/home/data/home_api.dart',
    "import 'package:goal_getter/core/api/api_route.dart';",
  ),
  'json-outside-domain': (
    'lib/features/home/domain/home_dashboard.dart',
    'int streak(Map<String, dynamic> body) => body.length;',
  ),
  'route-outside-router': (
    'lib/app/router/app_router.dart',
    "final route = GoRoute(path: '/x', builder: (c, s) => build());",
  ),
};

void main() {
  for (final MapEntry(key: rule, value: (home, code))
      in _outsideItsHub.entries) {
    group(rule, () {
      test('fails outside its hub', () {
        expect(_rules(_controller, code), contains(rule));
      });

      test('passes in its hub', () {
        expect(_rules(home, code), isNot(contains(rule)));
      });
    });
  }

  group('api-outside-data, the other doors', () {
    test('fails on the client and its provider, relative or not', () {
      expect(
        _rules(
          'lib/core/services/auth_service.dart',
          "import '../api/api_client.dart';",
        ),
        contains('api-outside-data'),
      );
      expect(
        _rules(
          _controller,
          "import 'package:goal_getter/core/api/api_providers.dart';",
        ),
        contains('api-outside-data'),
      );
    });

    test('passes on the failure types, which any layer catches', () {
      expect(
        _rules(
          _controller,
          "import 'package:goal_getter/core/api/api_exception.dart';",
        ),
        isEmpty,
      );
    });
  });

  group('json-outside-domain, the other shapes', () {
    test('fails on the codec and on Object? maps', () {
      expect(
        _rules(_controller, 'final body = jsonDecode(text);'),
        contains('json-outside-domain'),
      );
      expect(
        _rules(_controller, 'void f(Map<String, Object?> json) {}'),
        contains('json-outside-domain'),
      );
    });

    test('passes in data/, where a request body is written', () {
      expect(
        _rules(
          'lib/features/home/data/home_api.dart',
          'class HomeApi { Map<String, dynamic> body() => {}; }',
        ),
        isEmpty,
      );
    });
  });

  group('data-defines-api-only', () {
    const path = 'lib/features/goals/data/goals_api.dart';

    test('fails on a model declared beside the API', () {
      expect(
        _rules(path, 'class GoalsApi {}\n\nclass GoalPage {}\n'),
        contains('data-defines-api-only'),
      );
      expect(
        _rules(path, 'class GoalsApi {}\n\nenum GoalFilter { all }\n'),
        contains('data-defines-api-only'),
      );
    });

    test('passes on the API class alone, and anywhere else', () {
      expect(_rules(path, 'class GoalsApi {}\n'), isEmpty);
      expect(
        _rules(
          'lib/features/goals/domain/goal.dart',
          'class Goal {}\n\nclass GoalPage {}\n',
        ),
        isEmpty,
      );
    });
  });

  group('cross-feature-presentation', () {
    const widget =
        "import 'package:goal_getter/features/lessons/presentation/widgets/lesson_clock.dart';";

    test("fails on a feature drawing with another feature's widget", () {
      expect(
        _rules(
          'lib/features/home/presentation/widgets/recent_lessons_list.dart',
          widget,
        ),
        contains('cross-feature-presentation'),
      );
    });

    test('passes inside the feature, from lib/core/, and for controllers', () {
      expect(
        _rules(
          'lib/features/lessons/presentation/screens/finish_lesson_screen.dart',
          widget,
        ),
        isEmpty,
      );
      expect(
        _rules(
          'lib/features/home/presentation/widgets/recent_lessons_list.dart',
          "import 'package:goal_getter/core/widgets/lesson_clock.dart';",
        ),
        isEmpty,
      );
      expect(
        _rules(
          'lib/features/lessons/presentation/controllers/lesson_controller.dart',
          "import 'package:goal_getter/features/home/presentation/controllers/home_controller.dart';",
        ),
        isEmpty,
      );
    });
  });
}
