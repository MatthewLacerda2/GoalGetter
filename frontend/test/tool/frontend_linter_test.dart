import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// One test per rule in `tool/frontend_linter.dart`: a snippet that must fail
/// and a snippet that must pass. A rule nobody has seen fail is a rule nobody
/// can trust.

const _screen = 'lib/features/home/presentation/screens/home_screen.dart';
const _themeFile = 'lib/app/theme/app_theme.dart';

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
}
