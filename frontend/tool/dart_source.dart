/// Reading Dart source the way the house rules need it: comments and string
/// contents blanked, code lines counted, function bodies found, string
/// literals read back.
///
/// Split out of `frontend_linter.dart` so that file holds the rules and this
/// one holds the scanning they share. Everything here is a pure function over
/// a source string, which is what makes every rule testable.
library;

/// One rule broken at one line of one file.
class Violation {
  final int line;
  final String rule;
  final String message;

  const Violation(this.line, this.rule, this.message);

  @override
  String toString() => 'Line $line: [$rule] $message';
}

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
int lineAt(String source, int index) =>
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
int matchBracket(String src, int open) {
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
      final end = matchBracket(stripped, i);
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
    final close = matchBracket(stripped, i);
    if (close < 0) continue;
    final end = bodyEnd(close + 1);
    if (end == null) continue;
    spans.add(FunctionSpan(
      name,
      lineAt(stripped, i),
      lineAt(stripped, end),
    ));
    i = close;
  }

  // Getters have no parameter list, so they need their own pass.
  for (final m in RegExp(r'\bget\s+([A-Za-z_]\w*)\s*').allMatches(stripped)) {
    final end = bodyEnd(m.end);
    if (end == null) continue;
    spans.add(FunctionSpan(
      m.group(1)!,
      lineAt(stripped, m.start),
      lineAt(stripped, end),
    ));
  }

  return spans;
}

/// The contents of the string literal whose opening quote is at [quote] in
/// [source], or null when there is no literal there.
///
/// The linter reads literals back out of the *raw* source: `stripSource`
/// blanks their contents, and the hardcoded-string rule has to see them.
String? literalAt(String source, int quote) {
  final c = source[quote];
  if (c != "'" && c != '"') return null;
  final triple = source.startsWith(c * 3, quote);
  final mark = triple ? c * 3 : c;
  var j = quote + mark.length;
  final buffer = StringBuffer();
  while (j < source.length) {
    if (source[j] == r'\') {
      buffer.write(source.substring(j, j + 2 <= source.length ? j + 2 : j + 1));
      j += 2;
      continue;
    }
    if (source.startsWith(mark, j)) return buffer.toString();
    if (!triple && source[j] == '\n') return buffer.toString();
    buffer.write(source[j]);
    j++;
  }
  return buffer.toString();
}

final RegExp _interpolation = RegExp(r'\$(?:\{[^}]*\}|[A-Za-z_]\w*)');

/// True when [literal] writes a value into itself: `'$count XP'` does,
/// `'Retry'` does not.
bool hasInterpolation(String literal) => _interpolation.hasMatch(literal);

/// What [literal] writes of its own, the interpolated values taken out:
/// `'$count XP'` writes `' XP'`, `'$count'` writes nothing.
String ownText(String literal) => literal.replaceAll(_interpolation, '');

/// [source] with its comments and string contents blanked, but the
/// expressions interpolated into strings kept: `'${l10n.videos} (3)'` still
/// reads `l10n.videos`, while `'Go book'` reads nothing.
///
/// This is what "the code names it" means for a rule that looks for a name,
/// because an interpolation is code that happens to live inside a string. A
/// comment that spells an interpolation is restored too: the rule would
/// rather keep a key than delete one that is read.
String stripToCode(String source) {
  final chars = stripSource(source).split('');
  for (final match in _interpolation.allMatches(source)) {
    final inner = stripSource(match.group(0)!);
    for (var i = 0; i < inner.length; i++) {
      chars[match.start + i] = inner[i];
    }
  }
  return chars.join();
}
