import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/core/utils/theme_mode_provider.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The name of [mode] as the profile's theme tile shows it.
String themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => l10n.themeSystem,
    ThemeMode.light => l10n.themeLight,
    ThemeMode.dark => l10n.themeDark,
  };
}

IconData _themeModeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}

/// The three theme options, beside the language picker on the profile page.
/// A tap repaints the app at once and is remembered on the device (#178).
void showThemeModeSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.chip)),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      final current = ref.read(themeModeProvider);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return ListTile(
              leading: Icon(_themeModeIcon(mode)),
              title: Text(themeModeLabel(l10n, mode)),
              trailing: mode == current ? const Icon(Icons.check) : null,
              onTap: () {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
                Navigator.of(sheetContext).pop();
              },
            );
          }).toList(),
        ),
      );
    },
  );
}

/// The current mode, on the right of the profile's theme tile.
class ThemeModeValue extends StatelessWidget {
  const ThemeModeValue({required this.mode, super.key});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      themeModeLabel(AppLocalizations.of(context), mode),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
