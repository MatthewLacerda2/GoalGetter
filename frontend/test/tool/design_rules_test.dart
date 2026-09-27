import 'package:flutter_test/flutter_test.dart';

import '../../tool/frontend_linter.dart';

/// The rules of `tool/design_rules.dart`: a colour, a type size, a corner, a
/// gap or a size is decided in `lib/core/theme/` and nowhere else. One
/// snippet that must fail and one that must pass per shape.

const _screen = 'lib/features/home/presentation/screens/home_screen.dart';
const _themeFile = 'lib/core/theme/app_theme.dart';

List<String> _rules(String source, {String path = _screen}) =>
    lintSource(path, source).map((v) => v.rule).toList();

void main() {
  group('no-color-literal', () {
    test('fails on Colors.* and on a hex Color', () {
      expect(_rules('final a = Colors.red;'), contains('no-color-literal'));
      expect(
        _rules('const a = Color(0xFF00FF00);'),
        contains('no-color-literal'),
      );
      expect(
        _rules('final a = Color.fromARGB(255, 1, 2, 3);'),
        contains('no-color-literal'),
      );
    });

    // #227: a tint is a colour decision like the hex it tints.
    test('fails on a colour derived with an alpha of its own', () {
      expect(
        _rules('final a = scheme.primary.withValues(alpha: 0.2);'),
        contains('no-color-literal'),
      );
      expect(
        _rules('final a = scheme.primary.withOpacity(0.5);'),
        contains('no-color-literal'),
      );
      expect(
        _rules('const o = Opacity(opacity: 0.6, child: x);'),
        contains('no-color-literal'),
      );
      expect(
        _rules('final o = Opacity(opacity: sent ? 1 : 0.6, child: x);'),
        contains('no-color-literal'),
      );
    });

    // #227: the fallback was a light-mode colour the dark theme could get.
    test('fails on the extension looked up with a fallback', () {
      expect(
        _rules(
          'final c = Theme.of(context).extension<CustomColors>()?.success '
          '?? AppTheme.success;',
        ),
        contains('no-color-literal'),
      );
    });

    test('passes on a colour and an alpha taken from the theme', () {
      expect(
        _rules('final a = Theme.of(context).colorScheme.primary;'),
        isEmpty,
      );
      expect(_rules('final a = CustomColors.of(context).success;'), isEmpty);
      expect(
        _rules('final a = scheme.primary.withValues(alpha: AppOpacity.tint);'),
        isEmpty,
      );
      expect(
        _rules('final o = Opacity(opacity: sent ? 1 : 0, child: x);'),
        isEmpty,
      );
    });

    test('passes inside lib/core/theme/, where the values live', () {
      expect(_rules('const a = Colors.red;', path: _themeFile), isEmpty);
    });

    test('ignores a colour named in a comment or a string', () {
      expect(_rules('// Colors.red is forbidden here.'), isEmpty);
      expect(_rules("final a = 'Color(0xFF0000FF)';"), isEmpty);
    });
  });

  group('no-font-size', () {
    test('fails on a hardcoded fontSize, prefixed ones included', () {
      expect(
        _rules('const s = TextStyle(fontSize: 14);'),
        contains('no-font-size'),
      );
      // #227: `\bfontSize` never saw BottomNavigationBar's own two.
      expect(
        _rules('final b = BottomNavigationBar(selectedFontSize: 10);'),
        contains('no-font-size'),
      );
    });

    test('passes on a size taken from the text theme', () {
      expect(
        _rules('final s = Theme.of(context).textTheme.bodyMedium;'),
        isEmpty,
      );
    });
  });

  group('no-radius-literal', () {
    test('fails on a radius written as a number', () {
      expect(
        _rules('final r = BorderRadius.circular(12);'),
        contains('no-radius-literal'),
      );
      expect(
        _rules('const r = Radius.circular(8.0);'),
        contains('no-radius-literal'),
      );
    });

    test('passes on an AppRadius token', () {
      expect(
        _rules('final r = BorderRadius.circular(AppRadius.card);'),
        isEmpty,
      );
      expect(_rules('const r = AppRadius.cardBorder;'), isEmpty);
    });
  });

  group('no-spacing-literal', () {
    test('fails on a padding written as a number', () {
      expect(
        _rules('const p = EdgeInsets.all(16);'),
        contains('no-spacing-literal'),
      );
      expect(
        _rules('const p = EdgeInsets.symmetric(horizontal: 12, vertical: 8);'),
        contains('no-spacing-literal'),
      );
    });

    test('passes on an AppSpacing token, and on EdgeInsets.zero', () {
      expect(_rules('const p = EdgeInsets.all(AppSpacing.md);'), isEmpty);
      expect(_rules('const p = EdgeInsets.zero;'), isEmpty);
    });
  });

  // #227: the spacing rule covered EdgeInsets only, so a gap written as a
  // SizedBox, an icon's size and a spinner's stroke all passed.
  group('no-size-literal', () {
    test('fails on a gap, an icon size and a stroke written as numbers', () {
      for (final source in [
        'const g = SizedBox(height: 24);',
        'const g = SizedBox(width: 12.0);',
        'const i = Icon(Icons.timer, size: 18);',
        'const p = CircularProgressIndicator(strokeWidth: 2);',
        'const b = IconButton(iconSize: 28, onPressed: f, icon: i);',
        'final w = BorderSide(width: active ? 2 : 1);',
        'final s = style.copyWith(letterSpacing: 1.2, height: 1.6);',
        'const t = TabBar(dividerHeight: 1, tabs: []);',
      ]) {
        expect(_rules(source), contains('no-size-literal'), reason: source);
      }
    });

    test('fails on a Size, and on a double declared with a number', () {
      expect(
        _rules('const s = Size.fromHeight(6);'),
        contains('no-size-literal'),
      );
      expect(_rules('const double _gap = 24;'), contains('no-size-literal'));
    });

    test('passes on a token, on zero and on a multiplier', () {
      expect(_rules('const g = SizedBox(height: AppSpacing.xl);'), isEmpty);
      expect(_rules('const i = Icon(i, size: AppIconSize.sm);'), isEmpty);
      expect(_rules('const c = Card(elevation: 0);'), isEmpty);
      expect(
        _rules('final b = BoxConstraints(minHeight: h - AppSpacing.md * 2);'),
        isEmpty,
      );
    });

    test('passes on a number that is not a length', () {
      expect(_rules('const t = Text(x, maxLines: 2);'), isEmpty);
      expect(_rules('const e = Expanded(flex: 2, child: c);'), isEmpty);
    });

    test('passes inside lib/core/theme/', () {
      expect(_rules('const s = Size(0, 56);', path: _themeFile), isEmpty);
    });
  });
}
