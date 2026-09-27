/// House rules for the Flutter side, the mirror of `backend/tests/backend_linter.py`.
///
/// On every hand-written file under `lib/`:
///
///  1. a `.dart` file is at most 400 lines;
///  2. a function or method is at most 60 code lines (comments free, blanks count);
///  3. no colour literal, written or derived (`Colors.*`, `Color(0x…)`,
///     `.withValues(alpha: 0.2)`), and no fallback on the colour extension;
///  4. no `fontSize:` — type comes from `Theme.of(context).textTheme`;
///  5. no radius, padding or size literal — they come from `AppRadius`,
///     `AppSpacing` and `AppSizes`;
///  6. no user-facing string written in Dart — it comes from the ARB files;
///  7. no widget named after a failure outside `lib/core/`;
///  8. no `DevFixtures` named, and nothing imported from `lib/app/dev/` but
///     `devRoutes`, outside `lib/app/dev/`;
///  9. no file under `lib/core/` imports `lib/app/`;
/// 10. no screen or widget imports a feature's `data/`: a controller does;
/// 11. a feature's `presentation/` holds `controllers/`, `screens/` and
///     `widgets/`, and nothing else.
/// 12. each kind of thing is defined in its hub — HTTP in `lib/core/api/`,
///     backend calls in a `data/` layer, JSON in `domain/`, routes in
///     `lib/app/router/`, a widget two features share in `lib/core/widgets/`
///     (`tool/hub_rules.dart`, and CLAUDE.md's hub map).
///
/// Rules 3-5 live in `tool/design_rules.dart`, rule 6 in
/// `tool/string_rules.dart`, and rules 8-11 — the shape of `lib/` rather than
/// the text of a file — in `tool/layer_rules.dart`: read the one you are
/// about to trip. Rules 3-5 exempt `lib/core/theme/`, where the values live;
/// rules 6 and 8 exempt `lib/app/dev/`, the dev menu and its fixtures, a tool
/// for us written in English like the code and never shipped to a student.
///
/// Rules 1 and 2 hold for `test/` and `tool/` too, and a test is at most 50
/// code lines (`tool/test_rules.dart`). So does the comment rule: at most three
/// issue references per file, and no sentence dated "since #N"
/// (`tool/comment_rules.dart`).
///
/// Four more rules answer for the project rather than for one file — dead ARB
/// keys, half-done translations, orphan files and unused members. They live in
/// `tool/project_rules.dart` and run once, after the files; only `lib/` counts
/// as a reader, so a test does not keep dead code alive.
///
/// The per-file checks run on *stripped* source: comments removed and string
/// contents blanked, so a hex colour inside a doc comment or a literal string
/// is not a violation. Everything is exposed as pure functions (`lintSource`,
/// `projectViolations`) so each rule has a test in
/// `test/tool/frontend_linter_test.dart`.
library;

import 'dart:io';

import 'comment_rules.dart';
import 'dart_source.dart';
import 'design_rules.dart';
import 'hub_rules.dart';
import 'layer_rules.dart';
import 'project_rules.dart';
import 'string_rules.dart';
import 'test_rules.dart';

export 'comment_rules.dart';
export 'dart_source.dart';
export 'dead_members.dart';
export 'design_rules.dart';
export 'hub_rules.dart';
export 'layer_rules.dart';
export 'project_rules.dart';
export 'string_rules.dart';
export 'test_rules.dart';

/// A file is at most this many raw lines (CLAUDE.md, frontend house rules).
const int maxFileLines = 400;

/// A function or method is at most this many code lines.
const int maxFunctionLines = 60;

/// The name endings that say "this widget is how a failure is shown".
const List<String> failureSuffixes = [
  'Error',
  'ErrorView',
  'Failure',
  'FailureView',
];

/// The directories the linter reads: `lib/` is what the per-file rules judge,
/// and all of them are held to the length rules.
const List<String> sourceDirs = ['lib', 'test', 'tool', 'integration_test'];

/// True when [path] is a hand-written file the rules apply to.
bool isLintedPath(String path) {
  final p = path.replaceAll(r'\', '/');
  if (!p.endsWith('.dart')) return false;
  if (isGeneratedPath(p)) return false;
  if (p.contains('/l10n/generated/')) return false;
  return true;
}

/// True when [path] is written by `build_runner`.
bool isGeneratedPath(String path) =>
    path.endsWith('.g.dart') || path.endsWith('.freezed.dart');

/// The invented student. A fixture reaching a build a student runs is how
/// someone gets shown another student's questions, plan or lesson result
/// (#139), so the name may only be written where the fixtures live.
final RegExp _devFixtures = RegExp(r'\bDevFixtures\b');

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
  const help =
      'A failure is a snackbar or a FailureView, both in '
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

/// The two length rules, which hold for every hand-written file.
///
/// A test file's `main` is exempt from the function rule: it is the list of
/// the file's tests, and `test-length` measures each of them.
List<Violation> lengthViolations(
  String source,
  String stripped, {
  bool isTest = false,
}) {
  final violations = <Violation>[];
  final rawLines = source.split('\n');
  if (rawLines.isNotEmpty && rawLines.last.isEmpty) rawLines.removeLast();
  if (rawLines.length > maxFileLines) {
    violations.add(
      Violation(
        0,
        'file-length',
        'File exceeds the line limit: ${rawLines.length}/$maxFileLines lines',
      ),
    );
  }
  for (final span in findFunctions(stripped)) {
    if (isTest && span.name == 'main') continue;
    final length = codeLineCount(source, span.startLine, span.endLine);
    if (length > maxFunctionLines) {
      violations.add(
        Violation(
          span.startLine,
          'function-length',
          "Function '${span.name}' exceeds the line limit: "
              '$length/$maxFunctionLines code lines',
        ),
      );
    }
  }
  return violations;
}

/// Every violation in one file. [path] decides which rules apply.
List<Violation> lintSource(String path, String source) {
  final stripped = stripSource(source);
  final isTest = path.startsWith('test/');
  final violations = [
    ...lengthViolations(source, stripped, isTest: isTest),
    ...commentViolations(source),
    if (isTest) ...testLengthViolations(source),
  ];
  if (path.startsWith('lib/')) {
    violations.addAll(designViolations(path, stripped));
    if (!isDevFile(path)) {
      violations.addAll(stringViolations(source, stripped));
      for (final match in _devFixtures.allMatches(stripped)) {
        violations.add(
          Violation(
            lineAt(stripped, match.start),
            'no-dev-fixture',
            'Invented data belongs to the dev menu, in lib/app/dev/: a screen '
                'whose data did not reach it recovers it, or sends the student '
                'to a screen where the state is real',
          ),
        );
      }
    }
    // Only lib/core/ may define a widget named after a failure.
    if (!isCoreFile(path)) violations.addAll(failureWidgets(stripped));
    violations.addAll(layerViolations(path, source));
    violations.addAll(hubViolations(path, source, stripped));
  }
  violations.sort((a, b) => a.line.compareTo(b.line));
  return violations;
}

/// Every Dart file under [sourceDirs] that [keep] accepts, keyed by its path.
Map<String, String> _readDartSources(bool Function(String path) keep) {
  final sources = <String, String>{};
  for (final name in sourceDirs) {
    final dir = Directory(name);
    if (!dir.existsSync()) continue;
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!keep(path)) continue;
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
    final name = file.path.replaceAll(r'\', '/').split('/').last;
    if (!name.startsWith('app_') || !name.endsWith('.arb')) continue;
    sources[name.substring('app_'.length, name.length - '.arb'.length)] = file
        .readAsStringSync();
  }
  return sources;
}

void main() {
  if (!Directory('lib').existsSync()) {
    stdout.writeln('Error: Could not find lib directory.');
    exit(1);
  }

  final sources = _readDartSources(isLintedPath);
  final paths = sources.keys.toList()..sort();

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

  final project = projectViolations(
    sources,
    _readArbSources(),
    generated: _readDartSources(isGeneratedPath),
  );
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
