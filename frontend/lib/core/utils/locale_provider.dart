import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'settings_storage.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    final storage = ref.watch(settingsStorageProvider);
    return Locale(storage.readUserLanguageSync());
  }

  Future<void> setLanguage(String languageCode) async {
    final storage = ref.read(settingsStorageProvider);
    final success = await storage.writeUserLanguage(languageCode);
    if (success) {
      state = Locale(languageCode);
    }
  }
}

// Keep backwards compatibility alias
final localeProvider = localeNotifierProvider;
