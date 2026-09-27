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
///
/// What a string interpolates is code, and stays: `'${a ? 'x' : ''}$b'` reads
/// `'${a ? ' ' : ''}$b'`, so a rule sees what the interpolation calls and the
/// quotes nested in it never pair up with the outer ones (#262).
String stripSource(String source) {
  final out = List<String>.from(source.split(''));
  final text = <(int, int)>[];
  _scanCode(source, 0, text);
  for (final (from, to) in text) {
    for (var k = from; k < to; k++) {
      if (out[k] != '\n' && out[k] != '\r') out[k] = ' ';
    }
  }
  return out.join();
}

bool _isIdentifierChar(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

/// Scans code from [start], adding every comment and every string's text to
/// [text], and returns where it stopped: the `}` that closes an interpolation
/// when [inInterpolation], else the end of [src].
int _scanCode(
  String src,
  int start,
  List<(int, int)> text, {
  bool inInterpolation = false,
}) {
  final n = src.length;
  var i = start;
  var depth = 0;
  while (i < n) {
    final c = src[i];
    if (src.startsWith('//', i)) {
      var end = src.indexOf('\n', i);
      if (end < 0) end = n;
      text.add((i, end));
      i = end;
    } else if (src.startsWith('/*', i)) {
      var end = src.indexOf('*/', i + 2);
      end = end < 0 ? n : end + 2;
      text.add((i, end));
      i = end;
    } else if (c == "'" || c == '"') {
      i = _scanLiteral(src, i, text).end;
    } else {
      if (c == '{') depth++;
      if (c == '}') {
        if (depth == 0 && inInterpolation) return i;
        depth--;
      }
      i++;
    }
  }
  return n;
}

/// Scans the literal whose opening quote is at [quote]: its text goes to
/// [text], the code of each `${…}` is scanned as code. Returns where its
/// contents end (the closing quote) and where the literal ends (past it).
({int contentEnd, int end}) _scanLiteral(
  String src,
  int quote,
  List<(int, int)> text,
) {
  final n = src.length;
  final c = src[quote];
  final raw =
      quote > 0 &&
      src[quote - 1] == 'r' &&
      (quote < 2 || !_isIdentifierChar(src[quote - 2]));
  final mark = src.startsWith(c * 3, quote) ? c * 3 : c;
  var j = quote + mark.length;
  var from = j;
  while (j < n) {
    if (src.startsWith(mark, j)) {
      text.add((from, j));
      return (contentEnd: j, end: j + mark.length);
    }
    if (mark.length == 1 && src[j] == '\n') break;
    if (!raw && src[j] == r'\') {
      j += 2;
    } else if (!raw && src.startsWith(r'${', j)) {
      text.add((from, j));
      j = _scanCode(src, j + 2, text, inInterpolation: true) + 1;
      from = j;
    } else if (!raw && RegExp(r'\$[A-Za-z_]').matchAsPrefix(src, j) != null) {
      text.add((from, j));
      j++;
      while (j < n && RegExp('[A-Za-z0-9_]').hasMatch(src[j])) {
        j++;
      }
      from = j;
    } else {
      j++;
    }
  }
  final end = j < n ? j : n;
  text.add((from, end));
  return (contentEnd: end, end: end);
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
    spans.add(FunctionSpan(name, lineAt(stripped, i), lineAt(stripped, end)));
    i = close;
  }

  // Getters have no parameter list, so they need their own pass.
  for (final m in RegExp(r'\bget\s+([A-Za-z_]\w*)\s*').allMatches(stripped)) {
    final end = bodyEnd(m.end);
    if (end == null) continue;
    spans.add(
      FunctionSpan(
        m.group(1)!,
        lineAt(stripped, m.start),
        lineAt(stripped, end),
      ),
    );
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
  final start = source.startsWith(c * 3, quote) ? quote + 3 : quote + 1;
  final end = _scanLiteral(source, quote, []).contentEnd;
  return source.substring(start, end);
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
/// because an interpolation is code that happens to live inside a string.
/// `stripSource` keeps those already; what this adds is a comment that
/// spells an interpolation, restored too: the rule would rather keep a key
/// than delete one that is read.
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
