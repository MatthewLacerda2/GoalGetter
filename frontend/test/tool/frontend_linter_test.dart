import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// One test per rule in `tool/frontend_linter.dart`: a snippet that must fail
/// and a snippet that must pass. A rule nobody has seen fail is a rule nobody
/// can trust. The rules split into their own files have their tests beside
/// this one: `design_rules_test.dart`, `string_rules_test.dart`,
/// `layer_rules_test.dart` and `project_rules_test.dart`.

const _screen = 'lib/features/home/presentation/screens/home_screen.dart';
const _themeFile = 'lib/core/theme/app_theme.dart';
const _devFile = 'lib/app/dev/dev_menu_screen.dart';
const _coreFile = 'lib/core/widgets/failure.dart';

List<String> _rules(String source, {String path = _screen}) =>
    lintSource(path, source).map((v) => v.rule).toList();

void main() {
  group('function-length', () {
    String body(int statements) {
      final lines = List.generate(statements, (i) => '  final a$i = $i;');
      return 'int f() {\n${lines.join('\n')}\n  return 0;\n}\n';
    }

    test('fails on a function of 61 code lines', () {
      // signature + 58 statements + return + closing brace = 61.
      expect(_rules(body(58)), contains('function-length'));
    });

    test('passes on a function of 60 code lines', () {
      expect(_rules(body(57)), isEmpty);
    });

    test('does not charge a function for its comments', () {
      final commented = 'int f() {\n${'  // a comment\n' * 40}'
          '${List.generate(57, (i) => '  final a$i = $i;').join('\n')}\n'
          '  return 0;\n}\n';
      expect(_rules(commented), isEmpty);
    });

    test('applies inside the theme too', () {
      expect(_rules(body(58), path: _themeFile), contains('function-length'));
    });
  });

  group('file-length', () {
    test('fails at 401 lines and passes at 400', () {
      expect(_rules('${'// line\n' * 401}'), contains('file-length'));
      expect(_rules('${'// line\n' * 400}'), isEmpty);
    });
  });

  group('own-failure-widget', () {
    test('fails on a feature that grows its own error widget', () {
      expect(
        _rules('class StepError extends StatelessWidget {}'),
        contains('own-failure-widget'),
      );
      expect(
        _rules('class LessonSubmitFailureView extends ConsumerWidget {}'),
        contains('own-failure-widget'),
      );
    });

    test('passes in lib/core/, where the two shapes live', () {
      expect(
        _rules('class FailureView extends StatelessWidget {}',
            path: _coreFile),
        isEmpty,
      );
    });

    test('passes on a model, which is not a widget', () {
      expect(_rules('class LessonFailure {}'), isEmpty);
      expect(_rules('class TutorError extends Exception {}'), isEmpty);
    });

    test('passes on a widget not named after a failure', () {
      expect(_rules('class GoalCard extends StatelessWidget {}'), isEmpty);
    });
  });

  group('core-imports-app', () {
    test('fails on a file under lib/core/ importing lib/app/', () {
      expect(
        _rules(
          "import 'package:goal_getter/app/router/app_router.dart';",
          path: 'lib/core/api/api_providers.dart',
        ),
        contains('core-imports-app'),
      );
      expect(
        _rules(
          "import '../../app/router/app_routes.dart';",
          path: 'lib/core/api/api_providers.dart',
        ),
        contains('core-imports-app'),
      );
    });

    test('passes on core importing core, and on app importing core', () {
      expect(
        _rules(
          "import 'package:goal_getter/core/utils/settings_storage.dart';",
          path: 'lib/core/api/api_providers.dart',
        ),
        isEmpty,
      );
      expect(
        _rules(
          "import 'package:goal_getter/core/api/api_providers.dart';",
          path: 'lib/app/router/app_router.dart',
        ),
        isEmpty,
      );
    });
  });

  group('no-dev-fixture', () {
    test('fails on a screen or a route reaching for invented data', () {
      expect(
        _rules('final a = state.extra as Args? ?? DevFixtures.goalQuestions;'),
        contains('no-dev-fixture'),
      );
      expect(
        _rules('import "package:goal_getter/app/dev/dev_fixtures.dart";\n'
            'final d = DevFixtures.goalDraft;'),
        contains('no-dev-fixture'),
      );
    });

    test('passes inside lib/app/dev/, where the fixtures live', () {
      expect(
        _rules('final d = DevFixtures.goalDraft;', path: _devFile),
        isEmpty,
      );
    });

    test('ignores the name in a comment or a string', () {
      expect(_rules('// DevFixtures is for the dev menu.'), isEmpty);
      expect(_rules("final s = 'DevFixtures';"), isEmpty);
    });

    // #227: the name rule reads names, so an alias declared in lib/app/dev/
    // carried the fixtures out under another one. Only `devRoutes` crosses.
    test('fails on reaching lib/app/dev/ for anything but devRoutes', () {
      const router = 'lib/app/router/app_router.dart';
      for (final source in [
        "import 'package:goal_getter/app/dev/dev_fixtures.dart';\n"
            'final g = Fixtures.goalDraft;',
        "import 'package:goal_getter/app/dev/dev_routes.dart';",
        "import '../dev/dev_routes.dart' show devRoutes, Fx;",
        "export 'package:goal_getter/app/dev/dev_routes.dart';",
      ]) {
        expect(
          _rules(source, path: router),
          contains('no-dev-fixture'),
          reason: source,
        );
      }
    });

    test('passes on the router importing devRoutes alone', () {
      expect(
        _rules(
          "import 'package:goal_getter/app/dev/dev_routes.dart'\n"
          '    show devRoutes;',
          path: 'lib/app/router/app_router.dart',
        ),
        isEmpty,
      );
    });
  });

  group('test-length', () {
    String aTest(int statements) {
      final lines = List.generate(statements, (i) => '    final a$i = $i;');
      return "  test('t', () {\n${lines.join('\n')}\n  });\n";
    }

    const testFile = 'test/features/a_test.dart';

    test('fails on a test of 51 code lines', () {
      // test( + 49 statements + closing line = 51.
      expect(
        _rules('void main() {\n${aTest(49)}}\n', path: testFile),
        contains('test-length'),
      );
    });

    test('passes on a test of 50 code lines', () {
      expect(_rules('void main() {\n${aTest(48)}}\n', path: testFile), isEmpty);
    });

    test("a test file's main is the list of its tests, not a function", () {
      final many = List.generate(4, (_) => aTest(20)).join();
      expect(_rules('void main() {\n$many}\n', path: testFile), isEmpty);
    });

    test('a test outside test/ is not judged as one', () {
      expect(_rules(aTest(49), path: 'tool/a.dart'), isEmpty);
    });
  });
}
