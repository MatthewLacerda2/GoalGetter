/// `unused-member`: a public function, method, getter or class under `lib/`
/// whose name the app never mentions again — the frontend's `vulture`
/// (`make back-deadcode` on the backend).
///
/// It reads names, not types, the way vulture does: a member is used when its
/// name appears as an identifier anywhere else in `lib/` or in the generated
/// files next to it (`*.g.dart` call the `@riverpod` functions by name). So
/// two members sharing a name keep each other alive, and the rule never fails
/// a member that is in fact read. What it adds is the one thing the analyzer
/// does not do: `dart analyze` reports an unused *private* member, never a
/// public one.
///
/// Tests are not readers (#227). A member only a test calls is code nobody
/// runs, kept alive by the test that exercises it: `SettingsStorage`'s
/// `getUserInfo` was read by nothing, and the orphan-file and unused-key rules
/// used to count a test's use the same way.
///
/// Not judged, each because something other than our code calls it:
///
///  * a private name — the analyzer already reports it (`unused_element`);
///  * an `@override` — the framework or the supertype calls it;
///  * [entryPoints] — called by Flutter, Dart or `jsonEncode`, never by name.
library;

import 'dart_source.dart';
import 'project_rules.dart';

/// Names only the platform calls. Each is called by name by something that
/// is not in `lib/`: Dart runs `main`, `jsonEncode` calls `toJson`.
const Set<String> entryPoints = {'main', 'toJson'};

final RegExp _typeDeclaration = RegExp(
  r'\b(?:class|mixin|enum|extension|typedef)\s+([A-Za-z_$][\w$]*)',
);

final RegExp _override = RegExp(r'@override\b');

/// True when the member declared at [index] carries `@override`: the
/// annotation sits between it and the end of the declaration before it.
bool _isOverride(String stripped, int index) {
  var start = index;
  while (start > 0 && !';{}'.contains(stripped[start - 1])) {
    start--;
  }
  return _override.hasMatch(stripped.substring(start, index));
}

/// Every public name declared in [stripped]: functions, methods, getters and
/// types, with the line each is declared on.
Iterable<(String, int)> declaredNames(String stripped) sync* {
  for (final span in findFunctions(stripped)) {
    // A capital is a constructor body or a pattern (`AsyncError() => …`):
    // its type is judged as a type, below.
    if (RegExp('^[A-Z]').hasMatch(span.name)) continue;
    yield (span.name, span.startLine);
  }
  for (final match in _typeDeclaration.allMatches(stripped)) {
    yield (match.group(1)!, lineAt(stripped, match.start));
  }
}

/// Members of the files in [lib] that nothing in [lib] or [generated] names
/// a second time. Both map a path to its source.
List<ProjectViolation> unusedMemberViolations(
  Map<String, String> lib,
  Map<String, String> generated,
) {
  final counts = <String, int>{};
  final identifier = RegExp(r'[A-Za-z_$][\w$]*');
  for (final source in [...lib.values, ...generated.values]) {
    for (final match in identifier.allMatches(stripToCode(source))) {
      counts.update(match.group(0)!, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  final violations = <ProjectViolation>[];
  for (final path in lib.keys.toList()..sort()) {
    final stripped = stripSource(lib[path]!);
    final seen = <String>{};
    for (final (name, line) in declaredNames(stripped)) {
      if (name.startsWith('_') || entryPoints.contains(name)) continue;
      if ((counts[name] ?? 0) > 1 || !seen.add(name)) continue;
      final at = stripped.split('\n').take(line - 1).join('\n').length + 1;
      if (_isOverride(stripped, at + stripped.substring(at).indexOf(name))) {
        continue;
      }
      violations.add(
        ProjectViolation(
          'unused-member',
          "$path:$line '$name' is declared and never used by the app: delete "
              'it (a test using it does not count)',
        ),
      );
    }
  }
  return violations;
}
