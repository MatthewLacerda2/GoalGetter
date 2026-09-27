import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// `hardcoded-string` (`tool/string_rules.dart`): every sentence a student
/// reads comes from the ARB files, whichever slot carries it to the screen.

const _screen = 'lib/features/home/presentation/screens/home_screen.dart';
const _devFile = 'lib/app/dev/dev_menu_screen.dart';

List<String> _rules(String source, {String path = _screen}) =>
    lintSource(path, source).map((v) => v.rule).toList();

void main() {
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

  // #227: these slots were left out because models use the same names — and
  // a model's field is how a sentence reached `Text(variable)` unseen.
  test('fails on a sentence in any named argument of a constructor', () {
    for (final source in [
      "const s = TextSpan(text: 'Tap here');",
      "const t = Tooltip(message: 'Delete the goal');",
      "const t = Tab(text: 'Videos');",
      "final s = StatData(title: t, text: 'Accuracy', icon: i, color: c);",
      "final s = GoalSection(title: 'About you');",
    ]) {
      expect(_rules(source), contains('hardcoded-string'), reason: source);
    }
  });

  test('fails on a format that spells a word of its own', () {
    expect(
      _rules(r"final t = Text('${days}d');"),
      contains('hardcoded-string'),
    );
    expect(
      _rules(r"final s = StatData(text: '$count days');"),
      contains('hardcoded-string'),
    );
  });

  test('fails on a literal the screen draws exactly, even punctuation', () {
    expect(
      _rules("final t = Text('  ·  ');"),
      contains('hardcoded-string'),
    );
  });

  test('passes on a string that came from the ARB files', () {
    expect(_rules('final t = Text(l10n.retry);'), isEmpty);
    expect(
      _rules('final t = Text(AppLocalizations.of(context).no);'),
      isEmpty,
    );
    expect(_rules('final s = StatData(text: l10n.accuracy);'), isEmpty);
  });

  test('passes on a value a screen only formats', () {
    expect(_rules(r"final t = Text('$percent%');"), isEmpty);
    expect(_rules(r"final t = Text('$index / $total');"), isEmpty);
    expect(_rules("final t = Text('');"), isEmpty);
    expect(_rules(r"final s = StatData(text: '+$elo');"), isEmpty);
    // #262: the nested quotes were read as a literal spelling `${elo >= 0 ? `.
    expect(
      _rules(r"final s = StatData(text: '${elo >= 0 ? '+' : ''}$elo');"),
      isEmpty,
    );
  });

  // #270: `detail : 'HTTP …'` is a ternary's else branch, not `detail:`.
  test("passes on a ternary's else branch passed positionally", () {
    expect(
      _rules(r"final e = ApiException(s, ok ? detail : 'HTTP $s', raw);"),
      isEmpty,
    );
    expect(
      _rules(
        "final e = Foo(\n  a,\n  ok\n      ? detail\n      : 'Retry',\n);",
      ),
      isEmpty,
    );
    expect(
      _rules("const f = Foo(text: 'Retry');"),
      contains('hardcoded-string'),
    );
    expect(
      _rules("const f = Foo(a,\n  text: 'Retry');"),
      contains('hardcoded-string'),
    );
  });

  test('passes on an identifier, and on a call that is not a constructor', () {
    expect(
      _rules(
        "final r = GoRoute(path: '/home', builder: b);",
        path: 'lib/app/router/app_router.dart',
      ),
      isEmpty,
    );
    expect(_rules("developer.log('offline', name: 'api');"), isEmpty);
    expect(
      _rules("const id = String.fromEnvironment('ID', defaultValue: 'x');"),
      isEmpty,
    );
  });

  test("passes on the product name, MaterialApp's title", () {
    expect(
      _rules("final a = MaterialApp.router(title: 'GoalGetter');"),
      isEmpty,
    );
  });

  test('passes inside lib/app/dev/, the menu we run ourselves', () {
    expect(_rules("const t = Text('Dev menu');", path: _devFile), isEmpty);
    expect(
      _rules("const s = InfoScreen(title: 'Nice streak!');", path: _devFile),
      isEmpty,
    );
  });
}
