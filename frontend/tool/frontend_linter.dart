/// House rules for the Flutter side, the mirror of `backend/tests/backend_linter.py`.
///
/// Six rules on every hand-written file under `lib/`:
///
///  1. a `.dart` file is at most 400 lines;
///  2. a function or method is at most 60 code lines (comments free, blanks count);
///  3. no colour literal (`Colors.*`, `Color(0x…)`, `Color.fromARGB(…)`);
///  4. no `fontSize:` — type comes from `Theme.of(context).textTheme`;
///  5. no radius or padding literal — they come from `AppRadius` / `AppSpacing`;
///  6. no user-facing string written in Dart — it comes from the ARB files;
///  7. no widget named after a failure outside `lib/core/`.
///
/// Rules 3-5 exist so the theme is the only place a colour, a type size, a
/// corner or a gap is decided. `lib/app/theme/` is where those values live, so
/// it is the one directory exempt from them. Rule 6 exists so every sentence a
/// student reads exists in all five locales; `lib/app/dev/` is exempt from it,
/// because the dev menu and its fixtures are a tool for us, written in English
/// like the code and the comments, and never shipped to a student.
///
/// Three more rules answer for the project rather than for one file — dead ARB
/// keys, half-done translations and orphan files. They live in
/// `tool/project_rules.dart` and run once, after the files.
///
/// The per-file checks run on *stripped* source: comments removed and string
/// contents blanked, so a hex colour inside a doc comment or a literal string
/// is not a violation. Everything is exposed as pure functions (`lintSource`,
/// `projectViolations`) so each rule has a test in
/// `test/tool/frontend_linter_test.dart`.
library;

import 'dart:io';

import 'dart_source.dart';
import 'project_rules.dart';

export 'dart_source.dart';
export 'project_rules.dart';

/// A file is at most this many raw lines (CLAUDE.md, frontend house rules).
const int maxFileLines = 400;

/// A function or method is at most this many code lines.
const int maxFunctionLines = 60;

/// The one directory allowed to write raw design values.
const String themeDir = 'lib/app/theme/';

/// The one directory allowed to write user-facing strings in Dart: the dev
/// menu and its fixtures are a tool for us, not a screen for a student.
const String devDir = 'lib/app/dev/';

/// The one directory allowed to define a widget named after a failure.
const String coreDir = 'lib/core/';

/// The name endings that say "this widget is how a failure is shown".
const List<String> failureSuffixes = [
  'Error',
  'ErrorView',
  'Failure',
  'FailureView',
];

/// The directories the linter reads: `lib/` is what it judges, the others are
/// read so a file that only a test reaches does not look like an orphan.
const List<String> sourceDirs = ['lib', 'test', 'tool', 'integration_test'];

/// True when [path] is a hand-written file the rules apply to.
bool isLintedPath(String path) {
  final p = path.replaceAll('\\', '/');
  if (!p.endsWith('.dart')) return false;
  if (p.endsWith('.g.dart') || p.endsWith('.freezed.dart')) return false;
  if (p.contains('/l10n/generated/')) return false;
  return true;
}

/// True when [path] may write raw colours, sizes, radii and spacing.
bool isThemeFile(String path) => path.replaceAll('\\', '/').contains(themeDir);

/// True when [path] may write user-facing strings in Dart.
bool isDevFile(String path) => path.replaceAll('\\', '/').contains(devDir);

/// True when [path] may define a widget named after a failure.
bool isCoreFile(String path) => path.replaceAll('\\', '/').contains(coreDir);

final RegExp _colorsDot = RegExp(r'\bColors\.[A-Za-z]');
final RegExp _colorHex = RegExp(r'\bColor\s*\(\s*0x');
final RegExp _colorFromArgb = RegExp(r'\bColor\.from(?:ARGB|RGBO)\s*\(');
final RegExp _fontSize = RegExp(r'\bfontSize\s*:');
final RegExp _radiusCall = RegExp(
  r'\b(?:BorderRadius|BorderRadiusDirectional|Radius)\.[A-Za-z]+\s*\(',
);
final RegExp _edgeInsetsCall = RegExp(
  r'\bEdgeInsets(?:Directional)?\.[A-Za-z]+\s*\(',
);
final RegExp _bareNumber = RegExp(r'(?<![A-Za-z0-9_$.])\d');

/// The slots a sentence a student reads goes through.
///
/// Deliberately narrow: a `Text`, the `…Text:` fields of a form field, the
/// tooltip and the semantic labels are slots that can hold nothing but prose.
/// `title:`, `label:`, `text:`, `content:` and `message:` are not on the list
/// — they are also the field names of our own models (the lesson stats, the
/// dev fixtures) and of `MaterialApp.title`, which is the product name, so
/// matching them would fail data that is not a sentence at all. A sentence
/// reaching a screen through one of those fields is still caught, because it
/// is a `Text` by the time it is drawn.
final RegExp _textWidget = RegExp(
  r'''\b(?:Text|SelectableText)\s*\(\s*['"]''',
);
final RegExp _textArgument = RegExp(
  r'''\b(?:hintText|labelText|helperText|errorText|tooltip|semanticLabel'''
  r'''|semanticsLabel)\s*:\s*['"]''',
);

/// A class declaration and what it extends: `class Foo extends Bar`.
///
/// A widget is a class extending something whose name ends in `Widget`
/// (`StatelessWidget`, `ConsumerWidget`, …), which is every widget in this
/// codebase and the one thing the rule needs to tell a widget from a model.
final RegExp _classDeclaration = RegExp(
  r'\bclass\s+([A-Za-z_$][\w$]*)[^{;]*?\bextends\s+([A-Za-z_$][\w$]*)',
);

/// Widgets in [stripped] whose name says they are how a failure is shown.
List<Violation> failureWidgets(String stripped) {
  const help = 'A failure is a snackbar or a FailureView, both in '
      'lib/core/widgets/failure.dart: call one instead of writing a third '
      'shape here';
  return [
    for (final match in _classDeclaration.allMatches(stripped))
      if (match.group(2)!.endsWith('Widget') &&
          failureSuffixes.any(match.group(1)!.endsWith))
        Violation(
          lineAt(stripped, match.start),
          'own-failure-widget',
          "'${match.group(1)}' is a feature's own error widget. $help",
        ),
  ];
}

/// Numeric literal anywhere in the balanced argument list opening at [open].
bool _hasNumericArgument(String stripped, int open) {
  final close = matchBracket(stripped, open);
  if (close < 0) return false;
  return _bareNumber.hasMatch(stripped.substring(open + 1, close));
}

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
bool _isHardcodedText(String source, int quote) {
  final literal = literalAt(source, quote);
  if (literal == null) return false;
  final own = ownText(literal);
  if (!hasInterpolation(literal)) return own.trim().isNotEmpty;
  return _letter.hasMatch(own);
}

/// Every violation in one file. [path] decides which rules apply.
List<Violation> lintSource(String path, String source) {
  final violations = <Violation>[];
  final rawLines = source.split('\n');
  if (rawLines.isNotEmpty && rawLines.last.isEmpty) rawLines.removeLast();
  if (rawLines.length > maxFileLines) {
    violations.add(Violation(
      0,
      'file-length',
      'File exceeds the line limit: ${rawLines.length}/$maxFileLines lines',
    ));
  }

  final stripped = stripSource(source);

  for (final span in findFunctions(stripped)) {
    final length = codeLineCount(source, span.startLine, span.endLine);
    if (length > maxFunctionLines) {
      violations.add(Violation(
        span.startLine,
        'function-length',
        "Function '${span.name}' exceeds the line limit: "
        '$length/$maxFunctionLines code lines',
      ));
    }
  }

  void report(
    RegExp pattern,
    String rule,
    String message, {
    bool Function(int index)? when,
  }) {
    for (final match in pattern.allMatches(stripped)) {
      if (when != null && !when(match.end - 1)) continue;
      violations.add(Violation(lineAt(stripped, match.start), rule, message));
    }
  }

  if (!isThemeFile(path)) {
    const colourHelp = 'Colour literals belong in the theme: use '
        'Theme.of(context).colorScheme or the CustomColors extension';
    report(_colorsDot, 'no-color-literal', colourHelp);
    report(_colorHex, 'no-color-literal', colourHelp);
    report(_colorFromArgb, 'no-color-literal', colourHelp);

    report(
      _fontSize,
      'no-font-size',
      'Type sizes belong in the theme: use Theme.of(context).textTheme',
    );

    report(
      _radiusCall,
      'no-radius-literal',
      'Corner radii belong in the theme: use an AppRadius token',
      when: (index) => _hasNumericArgument(stripped, index),
    );
    report(
      _edgeInsetsCall,
      'no-spacing-literal',
      'Padding and margins belong in the theme: use an AppSpacing token',
      when: (index) => _hasNumericArgument(stripped, index),
    );
  }

  if (!isDevFile(path)) {
    const stringHelp = 'User-facing strings belong in the ARB files: add a key '
        'to lib/l10n/app_en.arb and the other locales, then read it through '
        'AppLocalizations';
    report(
      _textWidget,
      'hardcoded-string',
      stringHelp,
      when: (index) => _isHardcodedText(source, index),
    );
    report(
      _textArgument,
      'hardcoded-string',
      stringHelp,
      when: (index) => _isHardcodedText(source, index),
    );
  }

  if (!isCoreFile(path)) violations.addAll(failureWidgets(stripped));

  violations.sort((a, b) => a.line.compareTo(b.line));
  return violations;
}

/// Every hand-written Dart file of the frontend, keyed by its path.
Map<String, String> _readDartSources() {
  final sources = <String, String>{};
  for (final name in sourceDirs) {
    final dir = Directory(name);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll('\\', '/');
      if (!isLintedPath(path)) continue;
      sources[path] = file.readAsStringSync();
    }
  }
  return sources;
}

/// The raw text of every `app_<locale>.arb`, keyed by its locale.
Map<String, String> _readArbSources() {
  final dir = Directory('lib/l10n');
  final sources = <String, String>{};
  if (!dir.existsSync()) return sources;
  for (final file in dir.listSync().whereType<File>()) {
    final name = file.path.replaceAll('\\', '/').split('/').last;
    if (!name.startsWith('app_') || !name.endsWith('.arb')) continue;
    sources[name.substring('app_'.length, name.length - '.arb'.length)] =
        file.readAsStringSync();
  }
  return sources;
}

void main() {
  if (!Directory('lib').existsSync()) {
    stdout.writeln('Error: Could not find lib directory.');
    exit(1);
  }

  final sources = _readDartSources();
  final paths = sources.keys.where((path) => path.startsWith('lib/')).toList()
    ..sort();

  var total = 0;
  for (final path in paths) {
    final violations = lintSource(path, sources[path]!);
    if (violations.isEmpty) continue;
    stdout.writeln('  File: $path');
    for (final violation in violations) {
      stdout.writeln('    $violation');
    }
    total += violations.length;
  }

  final project = projectViolations(sources, _readArbSources());
  if (project.isNotEmpty) {
    stdout.writeln('  Project:');
    for (final violation in project) {
      stdout.writeln('    $violation');
    }
    total += project.length;
  }

  if (total > 0) {
    stdout.writeln(
      '\n[LINT FAILURE] $total violation(s) across ${paths.length} files.',
    );
    exit(1);
  }
  stdout.writeln(
    '[LINT SUCCESS] ${paths.length} Dart files conform to the house rules.',
  );
  exit(0);
}
