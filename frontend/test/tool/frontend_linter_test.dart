import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// One test per rule in `tool/frontend_linter.dart`: a snippet that must fail
/// and a snippet that must pass. A rule nobody has seen fail is a rule nobody
/// can trust.

const _screen = 'lib/features/home/presentation/screens/home_screen.dart';
const _themeFile = 'lib/app/theme/app_theme.dart';
const _devFile = 'lib/app/dev/dev_menu_screen.dart';
const _coreFile = 'lib/core/widgets/failure.dart';

/// One ARB file, as its raw text: the linter reads the files, not a model.
String _arb(Map<String, String> messages) {
  final entries = messages.entries
      .map((e) => '  "${e.key}": "${e.value}"')
      .join(',\n');
  return '{\n$entries\n}';
}

List<String> _projectRules(
  Map<String, String> dart,
  Map<String, String> arb,
) =>
    projectViolations(dart, arb).map((v) => v.rule).toList();

List<String> _rules(String source, {String path = _screen}) =>
    lintSource(path, source).map((v) => v.rule).toList();

void main() {
  group('no-color-literal', () {
    test('fails on Colors.* and on a hex Color', () {
      expect(
        _rules('final a = Colors.red;'),
        contains('no-color-literal'),
      );
      expect(
        _rules('const a = Color(0xFF00FF00);'),
        contains('no-color-literal'),
      );
      expect(
        _rules('final a = Color.fromARGB(255, 1, 2, 3);'),
        contains('no-color-literal'),
      );
    });

    test('passes on a colour taken from the theme', () {
      expect(
        _rules('final a = Theme.of(context).colorScheme.primary;'),
        isEmpty,
      );
    });

    test('passes inside lib/app/theme/, where the values live', () {
      expect(_rules('const a = Colors.red;', path: _themeFile), isEmpty);
    });

    test('ignores a colour named in a comment or a string', () {
      expect(_rules('// Colors.red is forbidden here.'), isEmpty);
      expect(_rules("final a = 'Color(0xFF0000FF)';"), isEmpty);
    });
  });

  group('no-font-size', () {
    test('fails on a hardcoded fontSize', () {
      expect(
        _rules('const s = TextStyle(fontSize: 14);'),
        contains('no-font-size'),
      );
    });

    test('passes on a size taken from the text theme', () {
      expect(
        _rules('final s = Theme.of(context).textTheme.bodyMedium;'),
        isEmpty,
      );
    });
  });

  group('no-radius-literal', () {
    test('fails on a radius written as a number', () {
      expect(
        _rules('final r = BorderRadius.circular(12);'),
        contains('no-radius-literal'),
      );
      expect(
        _rules('const r = Radius.circular(8.0);'),
        contains('no-radius-literal'),
      );
    });

    test('passes on an AppRadius token', () {
      expect(_rules('final r = BorderRadius.circular(AppRadius.card);'), isEmpty);
      expect(_rules('const r = AppRadius.cardBorder;'), isEmpty);
    });
  });

  group('no-spacing-literal', () {
    test('fails on a padding written as a number', () {
      expect(
        _rules('const p = EdgeInsets.all(16);'),
        contains('no-spacing-literal'),
      );
      expect(
        _rules('const p = EdgeInsets.symmetric(horizontal: 12, vertical: 8);'),
        contains('no-spacing-literal'),
      );
    });

    test('passes on an AppSpacing token, and on EdgeInsets.zero', () {
      expect(
        _rules('const p = EdgeInsets.all(AppSpacing.md);'),
        isEmpty,
      );
      expect(_rules('const p = EdgeInsets.zero;'), isEmpty);
    });
  });

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

  group('hardcoded-string', () {
    test('fails on a sentence written in Dart', () {
      expect(_rules("const t = Text('Retry');"), contains('hardcoded-string'));
      expect(
        _rules("const f = TextField(hintText: 'Your answer');"),
        contains('hardcoded-string'),
      );
      expect(
        _rules("const i = IconButton(tooltip: 'Go back');"),
        contains('hardcoded-string'),
      );
    });

    test('fails on a format that spells a word of its own', () {
      expect(_rules(r"final t = Text('${days}d');"),
          contains('hardcoded-string'));
    });

    test('fails on a literal the screen draws exactly, even punctuation', () {
      expect(_rules(r"final t = Text('  \u00b7  ');"),
          contains('hardcoded-string'));
    });

    test('passes on a string that came from the ARB files', () {
      expect(_rules('final t = Text(l10n.retry);'), isEmpty);
      expect(_rules('final t = Text(AppLocalizations.of(context).no);'),
          isEmpty);
    });

    test('passes on a value a screen only formats', () {
      expect(_rules(r"final t = Text('$percent%');"), isEmpty);
      expect(_rules(r"final t = Text('$index / $total');"), isEmpty);
      expect(_rules("final t = Text('');"), isEmpty);
    });

    test('passes inside lib/app/dev/, the menu we run ourselves', () {
      expect(_rules("const t = Text('Dev menu');", path: _devFile), isEmpty);
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

  group('unused-l10n-key', () {
    test('fails on a key no Dart file names', () {
      expect(
        _projectRules(
          {'lib/main.dart': 'final s = l10n.kept;'},
          {'en': _arb({'kept': 'Kept', 'dead': 'Dead'})},
        ),
        ['unused-l10n-key'],
      );
    });

    test('passes on a key read from code, even inside an interpolation', () {
      expect(
        _projectRules(
          {'lib/main.dart': r"final s = '${l10n.kept} (1)';"},
          {'en': _arb({'kept': 'Kept'})},
        ),
        isEmpty,
      );
    });

    test('a key named only inside a string or a comment is dead', () {
      expect(
        _projectRules(
          {'lib/main.dart': "// kept\nfinal s = 'a kept thing';"},
          {'en': _arb({'kept': 'Kept'})},
        ),
        ['unused-l10n-key'],
      );
    });
  });

  group('missing-translation', () {
    test('fails on a key the template has and another locale does not', () {
      expect(
        _projectRules(
          {'lib/main.dart': 'final s = l10n.hello;'},
          {'en': _arb({'hello': 'Hello'}), 'pt': _arb({})},
        ),
        ['missing-translation'],
      );
    });

    test('passes when every locale has every key', () {
      expect(
        _projectRules(
          {'lib/main.dart': 'final s = l10n.hello;'},
          {'en': _arb({'hello': 'Hello'}), 'pt': _arb({'hello': 'Ola'})},
        ),
        isEmpty,
      );
    });
  });

  group('orphan-file', () {
    test('fails on a file under lib/ that nothing imports', () {
      expect(
        _projectRules({'lib/a.dart': '', 'lib/main.dart': ''}, {}),
        ['orphan-file'],
      );
    });

    test('passes on a file a package: or a relative import reaches', () {
      expect(
        _projectRules({
          'lib/a.dart': "import 'package:goal_getter/b.dart';",
          'lib/b.dart': "import '../lib/c.dart';",
          'lib/c.dart': '',
          'lib/main.dart': "import 'a.dart';",
        }, {}),
        isEmpty,
      );
    });

    test('a file only a test reaches is reached', () {
      expect(
        _projectRules({
          'lib/a.dart': '',
          'test/a_test.dart': "import 'package:goal_getter/a.dart';",
        }, {}),
        isEmpty,
      );
    });
  });
}
