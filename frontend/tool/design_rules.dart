/// The rules that keep the theme the only place a colour, a type size, a
/// corner, a gap or a size is decided: `lib/core/theme/` is where those values
/// live, and every other file under `lib/` spends them by name.
///
/// Split out of `tool/frontend_linter.dart`, which runs them on every file
/// outside [themeDir]. They read *stripped* source (comments and string
/// contents blanked), so a hex colour in a doc comment is not a violation.
///
/// What counts as a design value, and why each shape is caught (#227):
///
///  * a colour, written (`Colors.red`, `Color(0x…)`) or derived from another
///    (`primary.withValues(alpha: 0.2)`): an alpha is as much a colour
///    decision as the hex it tints, and 14 of them lived in screens;
///  * a colour looked up with a fallback (`extension<CustomColors>()?.success
///    ?? …`): the fallback was a fixed light-mode value, so the dark theme
///    could paint with it. `CustomColors.of` cannot miss, so the lookup that
///    can is refused outright;
///  * a type size, including the `selectedFontSize:` a widget takes directly;
///  * a radius or a padding, as a number inside `BorderRadius.*`, `Radius.*`
///    or `EdgeInsets.*`;
///  * a size: the number given to any named argument that is a length —
///    `height:`, `width:`, `size:`, `strokeWidth:`, `iconSize:`, `spacing:`,
///    `elevation:`… — or to a `Size` constructor, or a `double` declared with
///    one. That is the `SizedBox(height: 24)` gap and the `Icon(size: 18)`,
///    which the padding rule alone let through.
///
/// Two numbers are not design values and stay writable: zero, which is the
/// absence of a size, and a number that multiplies or divides one
/// (`AppSpacing.md * 2` is "both sides", not a new step). An opacity of 0 or 1
/// is "hidden" or "shown", so those two stay writable in an alpha as well.
library;

import 'dart_source.dart';

/// The one directory allowed to write raw design values.
const String themeDir = 'lib/core/theme/';

/// True when [path] may write raw colours, sizes, radii and spacing.
bool isThemeFile(String path) => path.replaceAll(r'\', '/').contains(themeDir);

final RegExp _colorsDot = RegExp(r'\bColors\.[A-Za-z]');
final RegExp _colorHex = RegExp(r'\bColor\s*\(\s*0x');
final RegExp _colorFromArgb = RegExp(r'\bColor\.from(?:ARGB|RGBO)\s*\(');

/// A colour computed from another one with a number of its own.
final RegExp _derivedColour = RegExp(
  r'\.(?:withValues|withOpacity|withAlpha|withRed|withGreen|withBlue)\s*\(',
);

/// An `opacity:` argument, which is an alpha given to a whole subtree.
final RegExp _opacity = RegExp(r'\bopacity\s*:');

/// The theme extension read the way that can come back null.
final RegExp _extensionLookup = RegExp(r'\bextension\s*<\s*CustomColors\s*>');

/// `fontSize:`, and the `selectedFontSize:` / `unselectedFontSize:` a
/// `BottomNavigationBar` takes: the old `\bfontSize` missed every prefixed one.
final RegExp _fontSize = RegExp(r'(?:\b|(?<=[a-z]))[fF]ontSize\s*:');

final RegExp _radiusCall = RegExp(
  r'\b(?:BorderRadius|BorderRadiusDirectional|Radius)\.[A-Za-z]+\s*\(',
);
final RegExp _edgeInsetsCall = RegExp(
  r'\bEdgeInsets(?:Directional)?\.[A-Za-z]+\s*\(',
);

/// A named argument that is a length. The name ends in one of the words
/// Flutter uses for one, so `minHeight`, `dividerHeight`, `blockSpacing` and
/// `iconSize` are all read, and a type size (`fontSize`) is left to its own
/// rule.
final RegExp _sizeArgument = RegExp(
  r'\b(?![A-Za-z]*[fF]ontSize\b)[A-Za-z]*'
  '(?:[sS]ize|[wW]idth|[hH]eight|[sS]pacing|[eE]levation|[eE]xtent'
  r'|[tT]hickness|[iI]ndent|[dD]imension|[rR]adius)\s*:(?!:)',
);

/// The `Size` constructors, which take their lengths positionally.
final RegExp _sizeCall = RegExp(r'\bSize(?:\.[A-Za-z]+)?\s*\(');

/// A `double` declared with a literal, the way to smuggle a size past the
/// argument rule under a name: `const double _gap = 24;`.
final RegExp _doubleDeclaration = RegExp(r'\bdouble\s+[A-Za-z_$][\w$]*\s*=');

/// A numeric literal, not part of an identifier or a member access.
final RegExp _number = RegExp(
  r'(?<![A-Za-z0-9_$.])(\d+(?:\.\d+)?(?:[eE][-+]?\d+)?)(?![\w.])',
);

/// Numeric literals in [expression] that are design values: not zero (nor
/// one, for an [alpha]), and not a factor (`* 2`, `/ 2`, `2 *`).
bool _hasDesignNumber(String expression, {bool alpha = false}) {
  for (final match in _number.allMatches(expression)) {
    final value = double.tryParse(match.group(1)!);
    if (value == null || value == 0 || (alpha && value == 1)) continue;
    final before = expression.substring(0, match.start).trimRight();
    final after = expression.substring(match.end).trimLeft();
    if (before.endsWith('*') || before.endsWith('/')) continue;
    if (after.startsWith('*') || after.startsWith('/')) continue;
    return true;
  }
  return false;
}

/// The value of the named argument whose colon ends just before [from]: the
/// text up to the comma, bracket or semicolon that closes it at depth 0.
String argumentValue(String stripped, int from) {
  var depth = 0;
  for (var i = from; i < stripped.length; i++) {
    final c = stripped[i];
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      if (depth == 0) return stripped.substring(from, i);
      depth--;
    }
    if ((c == ',' || c == ';') && depth == 0) {
      return stripped.substring(from, i);
    }
  }
  return stripped.substring(from);
}

/// The argument list opening at [open], without its brackets.
String _arguments(String stripped, int open) {
  final close = matchBracket(stripped, open);
  return close < 0 ? '' : stripped.substring(open + 1, close);
}

/// A violation at every match of [pattern] in [stripped] that [when] accepts;
/// [when] is given the offset just past the match.
Iterable<Violation> _report(
  String stripped,
  RegExp pattern,
  String rule,
  String message, {
  bool Function(int end)? when,
}) sync* {
  for (final match in pattern.allMatches(stripped)) {
    if (when != null && !when(match.end)) continue;
    yield Violation(lineAt(stripped, match.start), rule, message);
  }
}

/// Colours: written, derived with an alpha of their own, or looked up with a
/// fallback.
Iterable<Violation> _colourViolations(String stripped) sync* {
  const help =
      'Colour literals belong in the theme: use '
      'Theme.of(context).colorScheme or CustomColors.of(context)';
  for (final pattern in [_colorsDot, _colorHex, _colorFromArgb]) {
    yield* _report(stripped, pattern, 'no-color-literal', help);
  }
  const alphaHelp =
      'A tint is a colour decision: name its alpha with an '
      'AppOpacity token, in lib/core/theme/';
  yield* _report(
    stripped,
    _derivedColour,
    'no-color-literal',
    alphaHelp,
    when: (end) => _hasDesignNumber(_arguments(stripped, end - 1), alpha: true),
  );
  yield* _report(
    stripped,
    _opacity,
    'no-color-literal',
    alphaHelp,
    when: (end) => _hasDesignNumber(argumentValue(stripped, end), alpha: true),
  );
  yield* _report(
    stripped,
    _extensionLookup,
    'no-color-literal',
    'Read the semantic colours with CustomColors.of(context): the theme '
        'always carries them, and a fallback is a colour of one mode only',
  );
}

/// Type sizes, corners and padding.
Iterable<Violation> _shapeViolations(String stripped) sync* {
  yield* _report(
    stripped,
    _fontSize,
    'no-font-size',
    'Type sizes belong in the theme: use Theme.of(context).textTheme',
  );
  yield* _report(
    stripped,
    _radiusCall,
    'no-radius-literal',
    'Corner radii belong in the theme: use an AppRadius token',
    when: (end) => _hasDesignNumber(_arguments(stripped, end - 1)),
  );
  yield* _report(
    stripped,
    _edgeInsetsCall,
    'no-spacing-literal',
    'Padding and margins belong in the theme: use an AppSpacing token',
    when: (end) => _hasDesignNumber(_arguments(stripped, end - 1)),
  );
}

/// Gaps and sizes: a length argument, a `Size`, a `double` declared with one.
Iterable<Violation> _sizeViolations(String stripped) sync* {
  const help =
      'Gaps and sizes belong in the theme: use an AppSpacing, '
      'AppSizes, AppIconSize or AppStroke token '
      '(lib/core/theme/app_dimens.dart)';
  for (final pattern in [_sizeArgument, _doubleDeclaration]) {
    yield* _report(
      stripped,
      pattern,
      'no-size-literal',
      help,
      when: (end) => _hasDesignNumber(argumentValue(stripped, end)),
    );
  }
  yield* _report(
    stripped,
    _sizeCall,
    'no-size-literal',
    help,
    when: (end) => _hasDesignNumber(_arguments(stripped, end - 1)),
  );
}

/// Every design-value violation in one file, read from [stripped] source.
List<Violation> designViolations(String path, String stripped) {
  if (isThemeFile(path)) return const [];
  // `preferredSize: Size.fromHeight(6)` is one number read by two rules.
  final seen = <String>{};
  return [
    for (final v in [
      ..._colourViolations(stripped),
      ..._shapeViolations(stripped),
      ..._sizeViolations(stripped),
    ])
      if (seen.add('${v.line} ${v.rule}')) v,
  ];
}
