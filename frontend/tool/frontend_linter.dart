/// House rules for the Flutter side, the mirror of `backend/tests/backend_linter.py`.
///
/// Five rules, all enforced on hand-written files under `lib/`:
///
///  1. a `.dart` file is at most 400 lines;
///  2. a function or method is at most 60 code lines (comments free, blanks count);
///  3. no colour literal (`Colors.*`, `Color(0x…)`, `Color.fromARGB(…)`);
///  4. no `fontSize:` — type comes from `Theme.of(context).textTheme`;
///  5. no radius or padding literal — they come from `AppRadius` / `AppSpacing`.
///
/// Rules 3-5 exist so the theme is the only place a colour, a type size, a
/// corner or a gap is decided. `lib/app/theme/` is where those values live, so
/// it is the one directory exempt from them.
///
/// The checks run on *stripped* source: comments removed and string contents
/// blanked, so a hex colour inside a doc comment or a literal string is not a
/// violation. Everything is exposed as pure functions (`lintSource`) so each
/// rule has a test in `test/tool/frontend_linter_test.dart`.
library;

import 'dart:io';

/// A file is at most this many raw lines (CLAUDE.md, frontend house rules).
const int maxFileLines = 400;

/// A function or method is at most this many code lines.
const int maxFunctionLines = 60;

/// The one directory allowed to write raw design values.
const String themeDir = 'lib/app/theme/';

/// Keywords that look like a call followed by a block, but are not functions.
const Set<String> _blockKeywords = {
  'if',
  'for',
  'while',
  'switch',
  'catch',
  'do',
  'else',
  'return',
  'await',
  'yield',
  'assert',
  'super',
  'this',
};

class Violation {
  final int line;
  final String rule;
  final String message;

  const Violation(this.line, this.rule, this.message);

  @override
  String toString() => 'Line $line: [$rule] $message';
}

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

/// Blanks out comments and string contents, keeping every character position
/// (and therefore every line number) intact.
String stripSource(String source) {
  final out = List<String>.from(source.split(''));
  var i = 0;
  final n = source.length;

  void blank(int from, int to) {
    for (var k = from; k < to && k < n; k++) {
      if (out[k] != '\n' && out[k] != '\r') out[k] = ' ';
    }
  }

  while (i < n) {
    final c = source[i];
    final next = i + 1 < n ? source[i + 1] : '';

    if (c == '/' && next == '/') {
      var end = source.indexOf('\n', i);
      if (end < 0) end = n;
      blank(i, end);
      i = end;
      continue;
    }
    if (c == '/' && next == '*') {
      var end = source.indexOf('*/', i + 2);
      end = end < 0 ? n : end + 2;
      blank(i, end);
      i = end;
      continue;
    }
    if (c == "'" || c == '"') {
      final triple = source.startsWith(c * 3, i);
      final quote = triple ? c * 3 : c;
      var j = i + quote.length;
      while (j < n) {
        if (source[j] == r'\') {
          j += 2;
          continue;
        }
        if (source.startsWith(quote, j)) break;
        if (!triple && source[j] == '\n') break;
        j++;
      }
      final end = j < n ? j + quote.length : n;
      blank(i + quote.length, end - quote.length);
      i = end;
      continue;
    }
    i++;
  }
  return out.join();
}

/// 1-based line number of [index] in [source].
int _lineAt(String source, int index) =>
    '\n'.allMatches(source.substring(0, index)).length + 1;

/// Code lines in the inclusive line range, the way the backend counts:
/// comment-only lines are free, blank lines are not.
int codeLineCount(String source, int startLine, int endLine) {
  final lines = source.split('\n');
  var count = 0;
  var inBlockComment = false;
  for (var n = startLine; n <= endLine && n <= lines.length; n++) {
    final text = lines[n - 1].trim();
    if (inBlockComment) {
      if (text.contains('*/')) inBlockComment = false;
      continue;
    }
    if (text.startsWith('/*')) {
      if (!text.contains('*/')) inBlockComment = true;
      continue;
    }
    if (text.startsWith('//') || text.startsWith('*')) continue;
    count++;
  }
  return count;
}

/// Index of the character matching the bracket that opens at [open].
int _matchBracket(String src, int open) {
  final closer = {'(': ')', '{': '}', '[': ']'}[src[open]];
  if (closer == null) return -1;
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (c == '(' || c == '{' || c == '[') depth++;
    if (c == ')' || c == '}' || c == ']') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

int _skipSpace(String src, int i) {
  while (i < src.length && src[i].trim().isEmpty) {
    i++;
  }
  return i;
}

/// The identifier ending just before [index], or '' when there is none.
String _identifierBefore(String src, int index) {
  var end = index;
  while (end > 0 && src[end - 1].trim().isEmpty) {
    end--;
  }
  var start = end;
  while (start > 0 && RegExp(r'[A-Za-z0-9_$]').hasMatch(src[start - 1])) {
    start--;
  }
  if (start == end) return '';
  if (start > 0 && src[start - 1] == '.') return '';
  return src.substring(start, end);
}

class FunctionSpan {
  final String name;
  final int startLine;
  final int endLine;
  const FunctionSpan(this.name, this.startLine, this.endLine);
}

/// Every named function, method, constructor body and getter in [stripped].
///
/// Anonymous closures are deliberately not counted on their own: a builder
/// closure is part of the function that writes it, and that function is what
/// the rule is about.
List<FunctionSpan> findFunctions(String stripped) {
  final spans = <FunctionSpan>[];

  /// End of the body that starts at [after]: a `{ … }` block or `=> …;`.
  int? bodyEnd(int after) {
    var i = _skipSpace(stripped, after);
    for (final modifier in ['async*', 'async', 'sync*']) {
      if (stripped.startsWith(modifier, i)) {
        i = _skipSpace(stripped, i + modifier.length);
        break;
      }
    }
    if (i < stripped.length && stripped[i] == '{') {
      final end = _matchBracket(stripped, i);
      return end < 0 ? null : end;
    }
    if (stripped.startsWith('=>', i)) {
      var depth = 0;
      for (var k = i + 2; k < stripped.length; k++) {
        final c = stripped[k];
        if (c == '(' || c == '{' || c == '[') depth++;
        if (c == ')' || c == '}' || c == ']') depth--;
        if (c == ';' && depth <= 0) return k;
      }
    }
    return null;
  }

  for (var i = 0; i < stripped.length; i++) {
    if (stripped[i] != '(') continue;
    final name = _identifierBefore(stripped, i);
    if (name.isEmpty || _blockKeywords.contains(name)) continue;
    final close = _matchBracket(stripped, i);
    if (close < 0) continue;
    final end = bodyEnd(close + 1);
    if (end == null) continue;
    spans.add(FunctionSpan(
      name,
      _lineAt(stripped, i),
      _lineAt(stripped, end),
    ));
    i = close;
  }

  // Getters have no parameter list, so they need their own pass.
  for (final m in RegExp(r'\bget\s+([A-Za-z_]\w*)\s*').allMatches(stripped)) {
    final end = bodyEnd(m.end);
    if (end == null) continue;
    spans.add(FunctionSpan(
      m.group(1)!,
      _lineAt(stripped, m.start),
      _lineAt(stripped, end),
    ));
  }

  return spans;
}

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

/// Numeric literal anywhere in the balanced argument list opening at [open].
bool _hasNumericArgument(String stripped, int open) {
  final close = _matchBracket(stripped, open);
  if (close < 0) return false;
  return _bareNumber.hasMatch(stripped.substring(open + 1, close));
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

  if (!isThemeFile(path)) {
    void report(
      RegExp pattern,
      String rule,
      String message, {
      bool Function(int index)? when,
    }) {
      for (final match in pattern.allMatches(stripped)) {
        if (when != null && !when(match.end - 1)) continue;
        violations.add(Violation(_lineAt(stripped, match.start), rule, message));
      }
    }

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

  violations.sort((a, b) => a.line.compareTo(b.line));
  return violations;
}

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stdout.writeln('Error: Could not find lib directory.');
    exit(1);
  }

  final files =
      libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => isLintedPath(file.path))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var total = 0;
  for (final file in files) {
    final violations = lintSource(file.path, file.readAsStringSync());
    if (violations.isEmpty) continue;
    stdout.writeln('  File: ${file.path}');
    for (final violation in violations) {
      stdout.writeln('    $violation');
    }
    total += violations.length;
  }

  if (total > 0) {
    stdout.writeln(
      '\n[LINT FAILURE] $total violation(s) across ${files.length} files.',
    );
    exit(1);
  }
  stdout.writeln(
    '[LINT SUCCESS] ${files.length} Dart files conform to the house rules.',
  );
  exit(0);
}
