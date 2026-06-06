import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'settings_storage.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    final initialLang = SettingsStorage.getUserLanguageSync();
    return Locale(initialLang);
  }

  Future<void> setLanguage(String languageCode) async {
    final success = await SettingsStorage.setUserLanguage(languageCode);
    if (success) {
      state = Locale(languageCode);
    }
  }
}

// Keep backwards compatibility alias
final localeProvider = localeNotifierProvider;
