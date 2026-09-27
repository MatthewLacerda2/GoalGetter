import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// The scanning every rule shares (`tool/dart_source.dart`): where a string
/// literal starts and ends, and what of it is text rather than code.

const _screen = 'lib/features/home/presentation/screens/home_screen.dart';

void main() {
  // #262: a literal nested in an interpolation closed the outer one early.
  group('a literal inside an interpolation', () {
    const source = r"final s = '${a ? 'x' : ''}$b';";

    test('is part of one literal to literalAt', () {
      expect(literalAt(source, source.indexOf("'")), r"${a ? 'x' : ''}$b");
    });

    test('leaves stripSource the interpolated code, text blanked', () {
      expect(stripSource(source), r"final s = '${a ? ' ' : ''}$b';");
    });

    test('hides no code from the rules', () {
      expect(
        lintSource(
          _screen,
          r"final s = '${a ? Color(0xFF000000) : ''}';",
        ).map((v) => v.rule),
        contains('no-color-literal'),
      );
    });
  });

  test('a raw string interpolates nothing and escapes nothing', () {
    const source = r"final r = RegExp(r'${\'); final c = Colors.red;";
    expect(literalAt(source, source.indexOf("'")), r'${\');
    expect(
      stripSource(source),
      "final r = RegExp(r'   '); final c = Colors.red;",
    );
  });

  test('a triple-quoted literal spans lines and nests interpolations', () {
    const source = "final s = '''\n\${a ? 'x' : \"y\"}\n''';";
    expect(stripSource(source), "final s = '''\n\${a ? ' ' : \" \"}\n''';");
  });
}
