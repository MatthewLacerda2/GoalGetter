import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// The rules no single file answers for (`tool/project_rules.dart`): dead ARB
/// keys, half-done translations, orphan files and unused members. Only the
/// app is a reader: a test reaching something does not keep it alive (#227).

/// One ARB file, as its raw text: the linter reads the files, not a model.
String _arb(Map<String, String> messages) {
  final entries = messages.entries
      .map((e) => '  "${e.key}": "${e.value}"')
      .join(',\n');
  return '{\n$entries\n}';
}

List<String> _projectRules(
  Map<String, String> dart,
  Map<String, String> arb, {
  Map<String, String> generated = const {},
}) =>
    projectViolations(dart, arb, generated: generated)
        .map((v) => v.rule)
        .toList();

void main() {
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

    test('a key only a test reads is dead', () {
      expect(
        _projectRules(
          {'lib/main.dart': '', 'test/a_test.dart': 'final s = l10n.kept;'},
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

    test('a file only a test reaches is an orphan', () {
      expect(
        _projectRules({
          'lib/a.dart': '',
          'lib/main.dart': '',
          'test/a_test.dart': "import 'package:goal_getter/a.dart';",
        }, {}),
        ['orphan-file'],
      );
    });

    test('two files only importing each other are orphans', () {
      expect(
        _projectRules({
          'lib/a.dart': "import 'b.dart';",
          'lib/b.dart': "import 'a.dart';",
          'lib/main.dart': '',
        }, {}),
        ['orphan-file', 'orphan-file'],
      );
    });

    // The web half of a conditional import is named after the `if`, not
    // before it: reading only the first URI would make it an orphan.
    test('both halves of a conditional import are reached', () {
      expect(
        _projectRules({
          'lib/main.dart':
              "import 'a.dart' if (dart.library.js_interop) 'a_web.dart';",
          'lib/a.dart': '',
          'lib/a_web.dart': '',
        }, {}),
        isEmpty,
      );
    });

    test('a library only its own part points back at is still an orphan', () {
      expect(
        _projectRules({
          'lib/a.dart': "part 'a_part.dart';",
          'lib/a_part.dart': "part of 'a.dart';",
          'lib/main.dart': '',
        }, {}),
        ['orphan-file', 'orphan-file'],
      );
    });
  });

  group('unused-member', () {
    const storage = "import 'storage.dart';\nvoid main() => S().read();";

    test('fails on a public method only a test calls', () {
      expect(
        _projectRules({
          'lib/main.dart': storage,
          'lib/storage.dart':
              'class S {\n  int read() => 1;\n  int getUserInfo() => 2;\n}',
          'test/s_test.dart': 'final x = s.getUserInfo();',
        }, {}),
        ['unused-member'],
      );
    });

    test('fails on a class nothing names', () {
      expect(
        _projectRules({
          'lib/main.dart': "import 'a.dart';",
          'lib/a.dart': 'class Unused {}',
        }, {}),
        ['unused-member'],
      );
    });

    test('passes on an override, a private member and an entry point', () {
      expect(
        _projectRules({
          'lib/main.dart': storage,
          'lib/storage.dart': 'class S {\n  int read() => 1;\n'
              '  @override\n  String toString() => "";\n'
              '  int _cache() => 1;\n  Map toJson() => {};\n}',
        }, {}),
        isEmpty,
      );
    });

    test('passes on a provider only its generated file names', () {
      expect(
        _projectRules(
          {
            'lib/main.dart': "import 'p.dart';",
            'lib/p.dart': "part 'p.g.dart';\nint counter(Ref ref) => 0;",
          },
          {},
          generated: {'lib/p.g.dart': 'final p = Provider(counter);'},
        ),
        isEmpty,
      );
    });
  });
}
