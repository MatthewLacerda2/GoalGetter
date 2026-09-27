/// The house rule for the tests themselves: `test-length`, the frontend's
/// mirror of the backend's 50 lines per test function (CLAUDE.md, "tests must
/// never be complex").
///
/// A Dart test is a closure handed to `test(…)` or `testWidgets(…)`, which the
/// function-length rule never sees — it deliberately does not count closures
/// on their own. So this measures the whole call, from `test(` to its closing
/// parenthesis, with the same counting as every other length rule: comment
/// lines are free, blank lines are not. A test that needs more is a feature
/// designed wrong, or a fixture that belongs in a helper.
library;

import 'dart_source.dart';

/// A test is at most this many code lines, as a backend test function is.
const int maxTestLines = 50;

final RegExp _testCall = RegExp(r'\b(?:test|testWidgets)\s*\(');

/// Every test in [source] longer than [maxTestLines].
List<Violation> testLengthViolations(String source) {
  final stripped = stripSource(source);
  final violations = <Violation>[];
  for (final match in _testCall.allMatches(stripped)) {
    final open = match.end - 1;
    final close = matchBracket(stripped, open);
    if (close < 0) continue;
    final start = lineAt(stripped, match.start);
    final length = codeLineCount(source, start, lineAt(stripped, close));
    if (length <= maxTestLines) continue;
    violations.add(
      Violation(
        start,
        'test-length',
        'Test exceeds the line limit: $length/$maxTestLines code lines. Move '
            'the setup into a helper, or split what it checks',
      ),
    );
  }
  return violations;
}
