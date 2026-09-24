/// The house rules that no single file can answer for.
///
/// Three rules, all run once over the whole frontend by
/// `tool/frontend_linter.dart`:
///
///  1. `unused-l10n-key` — a key defined in the ARB files and read nowhere;
///  2. `missing-translation` — a key in the template locale that another
///     locale does not have, so a translation can never be half-done;
///  3. `orphan-file` — a `.dart` file under `lib/` that nothing imports.
///
/// They are pure functions over maps of path to content: the linter does the
/// reading, this file does the deciding, and the tests pass literals.
library;

import 'dart:convert';

import 'dart_source.dart';

/// The locale every other one is measured against.
const String templateLocale = 'en';

/// The package name in `pubspec.yaml`, as `package:` imports spell it.
const String packagePrefix = 'package:goal_getter/';

/// Files under `lib/` that are allowed to have no importer: the entry point
/// Flutter calls itself.
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
      violations.add(ProjectViolation(
        'missing-translation',
        "Key '$key' is in app_$templateLocale.arb and not in app_$locale.arb",
      ));
    }
  }
  return violations;
}

final RegExp _directive = RegExp(
  r'''(?:import|export|part)\s+(?:r?['"])([^'"]+)['"]''',
);

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
/// `package:` imports of other packages and `dart:` imports are not files of
/// ours, so they are dropped.
Set<String> importedPaths(String path, String source) {
  final dir = path.contains('/')
      ? path.substring(0, path.lastIndexOf('/'))
      : '';
  final targets = <String>{};
  for (final match in _directive.allMatches(source)) {
    final uri = match.group(1)!;
    if (uri.startsWith(packagePrefix)) {
      targets.add('lib/${uri.substring(packagePrefix.length)}');
    } else if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
      targets.add(normalizePath('$dir/$uri'));
    }
  }
  return targets;
}

/// Files under `lib/` that no source in [sources] imports, exports or parts.
///
/// [sources] is every hand-written Dart file of the frontend keyed by its
/// path relative to `frontend/` — `test/` and `tool/` included, because a file
/// only a test reaches is still reached.
List<ProjectViolation> orphanFileViolations(Map<String, String> sources) {
  final reached = <String>{};
  for (final entry in sources.entries) {
    reached.addAll(importedPaths(entry.key, entry.value));
  }
  final orphans = sources.keys
      .where((path) => path.startsWith('lib/'))
      .where((path) => !rootDartFiles.contains(path))
      .where((path) => !reached.contains(path))
      .toList()
    ..sort();
  return [
    for (final path in orphans)
      ProjectViolation(
        'orphan-file',
        '$path is imported by nothing: wire it up or delete it',
      ),
  ];
}

/// Every project-wide violation.
///
/// [dartSources] is every hand-written Dart file keyed by its path relative to
/// `frontend/`; [arbSources] is the raw text of each `app_<locale>.arb` keyed
/// by its locale.
List<ProjectViolation> projectViolations(
  Map<String, String> dartSources,
  Map<String, String> arbSources,
) {
  final localeKeys = arbSources.map(
    (locale, source) => MapEntry(locale, arbKeys(source)),
  );
  final template = localeKeys[templateLocale] ?? <String>{};
  final readable = <String>[
    for (final entry in dartSources.entries)
      if (!entry.key.startsWith('tool/')) stripToCode(entry.value),
  ];
  return [
    ...unusedKeyViolations(template, readable),
    ...missingTranslationViolations(localeKeys),
    ...orphanFileViolations(dartSources),
  ];
}
