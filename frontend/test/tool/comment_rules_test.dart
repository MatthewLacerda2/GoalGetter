import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// The history gate fails a changelog, not a reason. References are built by
/// [_ref] rather than written out, so this file does not trip the rule.

const _screen = 'lib/features/home/presentation/screens/home_screen.dart';

String _ref(int number) => '#$number';

List<Violation> _found(String source, String rule) => lintSource(
  _screen,
  source,
).where((v) => v.rule == rule).toList();

void main() {
  group('issue-references', () {
    String header(int count) =>
        '/// ${List.generate(count, (i) => _ref(100 + i)).join(' ')}\n'
        'const int a = 1;\n';

    test('passes one reference per decision, up to the cap', () {
      expect(_found(header(maxIssueReferences), 'issue-references'), isEmpty);
    });

    test('fails a file past the cap, once, with the count', () {
      final found = _found(header(maxIssueReferences + 1), 'issue-references');
      expect(found, hasLength(1));
      expect(found.single.message, startsWith('${maxIssueReferences + 1} '));
    });

    test('also holds in test/ and tool/', () {
      final rules = lintSource(
        'test/example_test.dart',
        header(maxIssueReferences + 1),
      ).map((v) => v.rule);
      expect(rules, contains('issue-references'));
    });
  });

  group('dated-by-a-change', () {
    for (final word in ['since', 'Until', 'before', 'after', 'as of']) {
      test('fails "$word #N" on its line', () {
        final source = 'const int a = 1;\n// $word ${_ref(157)} it is so.\n';
        final found = _found(source, 'dated-by-a-change');
        expect(found.map((v) => v.line), [2]);
      });
    }

    test('passes present tense and lookalikes', () {
      const source =
          '// the key used to sign the token\n'
          '// a goal that no longer exists is a 404\n'
          '// an entity &#39; is not a reference\n'
          'const int a = 1;\n';
      expect(lintSource(_screen, source), isEmpty);
    });
  });
}
