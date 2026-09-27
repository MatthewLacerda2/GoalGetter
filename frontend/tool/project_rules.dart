/// The house rules that no single file can answer for.
///
/// Four rules, all run once over the whole frontend by
/// `tool/frontend_linter.dart`:
///
///  1. `unused-l10n-key` — a key defined in the ARB files and read nowhere;
///  2. `missing-translation` — a key in the template locale that another
///     locale does not have, so a translation can never be half-done;
///  3. `orphan-file` — a `.dart` file under `lib/` that `lib/main.dart` does
///     not reach;
///  4. `unused-member` — a public member nothing in `lib/` names again
///     (`tool/dead_members.dart`).
///
/// **Only the app is a reader** (#227). A key, a file or a member that only a
/// test reaches is code nobody runs, kept alive by the test that exercises
/// it; so `test/` and `tool/` never count as a use. Test helpers live under
/// `test/`.
///
/// They are pure functions over maps of path to content: the linter does the
/// reading, this file does the deciding, and the tests pass literals.
library;

import 'dart:convert';

import 'dart_source.dart';
import 'dead_members.dart';

/// The locale every other one is measured against.
const String templateLocale = 'en';

/// The package name in `pubspec.yaml`, as `package:` imports spell it.
const String packagePrefix = 'package:goal_getter/';

/// Where the app starts: every file under `lib/` must be reachable from here
/// through imports, exports and parts.
const Set<String> rootDartFiles = {'lib/main.dart'};

/// A rule broken by the project rather than by one line of one file.
class ProjectViolation {
  final String rule;
  final String message;

  const ProjectViolation(this.rule, this.message);

  @override
  String toString() => '[$rule] $message';
}

/// The message keys of one ARB file: its entries minus the `@` metadata.
Set<String> arbKeys(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) return <String>{};
  return decoded.keys.where((key) => !key.startsWith('@')).toSet();
}

final RegExp _identifier = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*');

/// Every identifier in [sources], which is what "a key is used" means here.
///
/// A key is reached as `l10n.keyName`, so its name has to appear literally
/// somewhere. Matching the bare identifier rather than `.keyName` keeps the
/// rule from ever failing a key that is in fact read — including one reached
/// by a computed lookup, where no `.keyName` is ever written.
///
/// [sources] is stripped source (`stripToCode`): a key named inside a comment
/// or inside a string — a test fixture that happens to say "book" — is not a
/// use of it, while `'${l10n.videos} (3)'` is.
Set<String> identifiersIn(Iterable<String> sources) {
  final found = <String>{};
  for (final source in sources) {
    for (final match in _identifier.allMatches(source)) {
      found.add(match.group(0)!);
    }
  }
  return found;
}

/// Keys defined in the ARB files that no Dart source mentions.
List<ProjectViolation> unusedKeyViolations(
  Set<String> keys,
  Iterable<String> dartSources,
) {
  final used = identifiersIn(dartSources);
  final dead = keys.where((key) => !used.contains(key)).toList()..sort();
  return [
    for (final key in dead)
      ProjectViolation(
        'unused-l10n-key',
        "Key '$key' is defined in the ARB files and read nowhere: "
            'delete it from every locale',
      ),
  ];
}

/// Keys the template locale has and another locale does not.
///
/// [localeKeys] is every locale, the template included; comparing it with
/// itself costs nothing and keeps the caller from having to remove it.
List<ProjectViolation> missingTranslationViolations(
  Map<String, Set<String>> localeKeys,
) {
  final template = localeKeys[templateLocale];
  if (template == null) return const [];
  final violations = <ProjectViolation>[];
  for (final locale in localeKeys.keys.toList()..sort()) {
    if (locale == templateLocale) continue;
    final missing = template.difference(localeKeys[locale]!).toList()..sort();
    for (final key in missing) {
      violations.add(
        ProjectViolation(
          'missing-translation',
          "Key '$key' is in app_$templateLocale.arb and not in app_$locale.arb",
        ),
      );
    }
  }
  return violations;
}

/// A whole `import` / `export` / `part` directive, up to its semicolon.
///
/// Matched whole rather than URI-first because one directive may name more
/// than one file: `import 'a.dart' if (dart.library.js_interop) 'b.dart';` is
/// how a file picks its web half, and reading only the first URI would make
/// the other half look like a file nothing imports.
final RegExp _directive = RegExp(
  r'''(?:^|\n)\s*(?:import|export|part)\s+(?!of\b)([^;]+);''',
);

/// Every quoted URI inside one directive.
final RegExp _directiveUri = RegExp('''r?['"]([^'"]+)['"]''');

/// Resolves `..` and `.` in a `/`-separated path.
String normalizePath(String path) {
  final parts = <String>[];
  for (final part in path.replaceAll('\\', '/').split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(part);
  }
  return parts.join('/');
}

/// The files [source] pulls in, as paths relative to `frontend/`.
///
/// Every URI of every directive, so a conditional import names both of its
/// halves. `package:` imports of other packages and `dart:` imports are not
/// files of ours, so they are dropped; `part of` names a library rather than
/// pulling a file in, so it is not a directive that reaches anything.
Set<String> importedPaths(String path, String source) => {
  for (final (_, target) in directiveTargets(path, source)) target,
};

/// [importedPaths], each with the offset in [source] where its directive
/// ends, so a rule about one import can say which line it is on.
Iterable<(int, String)> directiveTargets(String path, String source) =>
    directiveUses(path, source).map((use) => (use.$1, use.$2));

/// [directiveTargets], each with the whole directive that names it
/// (`import 'x.dart' show y`), for a rule about how a file is imported.
Iterable<(int, String, String)> directiveUses(
  String path,
  String source,
) sync* {
  final dir = path.contains('/')
      ? path.substring(0, path.lastIndexOf('/'))
      : '';
  for (final directive in _directive.allMatches(source)) {
    final text = directive.group(0)!.trim();
    for (final match in _directiveUri.allMatches(directive.group(1)!)) {
      final uri = match.group(1)!;
      if (uri.startsWith(packagePrefix)) {
        yield (
          directive.end,
          'lib/${uri.substring(packagePrefix.length)}',
          text,
        );
      } else if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
        yield (directive.end, normalizePath('$dir/$uri'), text);
      }
    }
  }
}

/// Files under `lib/` that the app never reaches: not [rootDartFiles], and
/// not pulled in, directly or through other files, by one.
///
/// Reachability rather than "somebody imports it": two dead files importing
/// each other are still dead, and a file only a test imports is code the app
/// never runs.
List<ProjectViolation> orphanFileViolations(Map<String, String> sources) {
  final reached = <String>{};
  final queue = [...rootDartFiles.where(sources.containsKey)];
  while (queue.isNotEmpty) {
    final path = queue.removeLast();
    if (!reached.add(path)) continue;
    queue.addAll(
      importedPaths(path, sources[path]!).where(sources.containsKey),
    );
  }
  final orphans =
      sources.keys
          .where((path) => path.startsWith('lib/'))
          .where((path) => !reached.contains(path))
          .toList()
        ..sort();
  return [
    for (final path in orphans)
      ProjectViolation(
        'orphan-file',
        '$path is not reached from lib/main.dart: wire it up or delete it '
            '(a test importing it does not count)',
      ),
  ];
}

/// Every project-wide violation.
///
/// [dartSources] is every hand-written Dart file keyed by its path relative to
/// `frontend/`; [arbSources] is the raw text of each `app_<locale>.arb` keyed
/// by its locale; [generated] is the `*.g.dart` files, which name the
/// `@riverpod` functions they wrap.
List<ProjectViolation> projectViolations(
  Map<String, String> dartSources,
  Map<String, String> arbSources, {
  Map<String, String> generated = const {},
}) {
  final localeKeys = arbSources.map(
    (locale, source) => MapEntry(locale, arbKeys(source)),
  );
  final template = localeKeys[templateLocale] ?? <String>{};
  final lib = {
    for (final entry in dartSources.entries)
      if (entry.key.startsWith('lib/')) entry.key: entry.value,
  };
  return [
    ...unusedKeyViolations(template, lib.values.map(stripToCode)),
    ...missingTranslationViolations(localeKeys),
    ...orphanFileViolations(dartSources),
    ...unusedMemberViolations(lib, generated),
  ];
}
