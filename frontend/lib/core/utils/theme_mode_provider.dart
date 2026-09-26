import 'package:flutter/material.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_mode_provider.g.dart';

/// Light, dark, or the phone's own mode — what `MaterialApp.themeMode` reads,
/// so a change repaints the whole app at once, the way `LocaleNotifier` does
/// for the language (#178).
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    return ref.watch(settingsStorageProvider).readThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsStorageProvider).writeThemeMode(mode);
  }
}
