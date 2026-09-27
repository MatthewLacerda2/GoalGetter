/// The rule that keeps every sentence a student reads in the ARB files, so it
/// exists in all five locales: `hardcoded-string`.
///
/// Split out of `tool/frontend_linter.dart`, which runs it on every file under
/// `lib/` outside `lib/app/dev/` (the menu we run ourselves, written in
/// English like the code).
///
/// A sentence reaches the screen through two kinds of slot, and both are read:
///
///  * `Text('…')` and `SelectableText('…')`, the positional slot;
///  * **any named argument of a constructor**: `Tooltip(message: '…')`,
///    `TextSpan(text: '…')`, `Tab(text: '…')`, and our own
///    `StatData(text: '…')` or `GoalDetailSection(title: '…')`, whose field
///    ends up in a `Text(variable)` further down. The rule used to list the
///    slots that could hold nothing but prose (`hintText:`, `tooltip:`…) and
///    left `text:`, `message:` and `title:` out because models use those names
///    too — which is exactly how a sentence reached `Text(variable)` unseen
///    (#227). A model built in `lib/` with a sentence in it is the same defect.
///
/// A constructor is a call whose name starts with a capital: `Foo(`, or
/// `Foo.named(`. A lowercase call (`developer.log(…, name: 'api')`) is not
/// something a student reads. The few named arguments that are identifiers
/// rather than prose (a route's `path:`, a log's `name:`…) are
/// [identifierArguments], and a literal that is a format rather than a word
/// (`'$percent%'`) passes as it always did.
///
/// What it still cannot see is a sentence assigned to a variable first
/// (`final label = 'Retry'; … Text(label)`): telling that string from a JSON
/// key needs the types, which only the analyzer has.
library;

import 'dart_source.dart';

/// Named arguments whose value is an identifier, never a sentence.
const Set<String> identifierArguments = {
  'debugLabel',
  'fontFamily',
  'key',
  'name',
  'package',
  'path',
  'restorationId',
  'scheme',
  'host',
};

/// Named arguments allowed a literal on one constructor only, each with its
/// reason.
const Map<String, Set<String>> constructorExemptions = {
  // The product name, the same word in every locale: the browser tab and the
  // task switcher read it, as `web/index.html`'s <title> does.
  'MaterialApp': {'title'},
  'MaterialApp.router': {'title'},
  // A build setting's fallback, read by the code and never drawn.
  'String.fromEnvironment': {'defaultValue'},
};

final RegExp _textWidget = RegExp(r'''\b(?:Text|SelectableText)\s*\(\s*['"]''');

/// A named argument whose value starts with a string literal: `name: '`.
///
/// The name has to open an argument — follow `(` or `,` — because the else
/// branch of a ternary has the same shape: `ok ? detail : 'HTTP $status'` is
/// a positional argument, not `detail:` (#270).
final RegExp _namedLiteral = RegExp(
  r'''(?<=[(,]\s*)\b([A-Za-z_$][\w$]*)\s*:\s*r?['"]''',
);

/// A letter in any of the five alphabets we ship.
final RegExp _letter = RegExp(r'\p{L}', unicode: true);

/// True when the literal whose quote is at [quote] is a string a student reads
/// rather than a value a screen formats.
///
/// `stripSource` keeps the quotes and blanks what is between them, so the
/// literal is read back out of the raw [source] at the same index. Two cases
/// are a sentence:
///
///  * a literal that interpolates nothing and is not blank. Whatever it is,
///    the screen draws exactly it — `'Retry'`, and the `'  ·  '` between two
///    facts, which is as much a decision about the layout of a language as
///    the words around it.
///  * a literal that frames interpolated values *and spells a word of its
///    own*: `'${days}d'` is a sentence, because the d of day is a t in German.
///    `'$percent%'` and `'$index / $total'` are not: a percent sign, a slash
///    and a space read the same in all five locales, and a key holding
///    punctuation is a key nobody would keep in step.
bool isHardcodedText(String source, int quote) {
  final literal = literalAt(source, quote);
  if (literal == null) return false;
  final own = ownText(literal);
  if (!hasInterpolation(literal)) return own.trim().isNotEmpty;
  return _letter.hasMatch(own);
}

/// The callee of the call whose argument list encloses [index], as written
/// (`Tooltip`, `EdgeInsets.all`, `print`), or null when [index] is not inside
/// a call's parentheses.
String? enclosingCallee(String stripped, int index) {
  var depth = 0;
  for (var i = index - 1; i >= 0; i--) {
    final c = stripped[i];
    if (c == ')' || c == ']' || c == '}') depth++;
    if (c == '(' || c == '[' || c == '{') {
      if (depth > 0) {
        depth--;
        continue;
      }
      if (c != '(') return null;
      final head = RegExp(
        r'([A-Za-z_$][\w$.]*)\s*(?:<[^()]*>)?\s*$',
      ).firstMatch(stripped.substring(0, i));
      return head?.group(1);
    }
  }
  return null;
}

/// `Foo(`, `Foo.named(` and `const Foo(`; not `foo.bar(` or `_helper(`.
bool _isConstructor(String callee) => RegExp('^[A-Z]').hasMatch(callee);

/// Every `hardcoded-string` violation in one file.
List<Violation> stringViolations(String source, String stripped) {
  const help =
      'User-facing strings belong in the ARB files: add a key to '
      'lib/l10n/app_en.arb and the other locales, then read it through '
      'AppLocalizations';
  final violations = <Violation>[];
  for (final match in _textWidget.allMatches(stripped)) {
    if (!isHardcodedText(source, match.end - 1)) continue;
    violations.add(
      Violation(lineAt(stripped, match.start), 'hardcoded-string', help),
    );
  }
  for (final match in _namedLiteral.allMatches(stripped)) {
    final name = match.group(1)!;
    if (identifierArguments.contains(name)) continue;
    final callee = enclosingCallee(stripped, match.start);
    if (callee == null || !_isConstructor(callee)) continue;
    if (constructorExemptions[callee]?.contains(name) ?? false) continue;
    if (!isHardcodedText(source, match.end - 1)) continue;
    violations.add(
      Violation(lineAt(stripped, match.start), 'hardcoded-string', help),
    );
  }
  return violations;
}
