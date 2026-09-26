import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'settings_storage.dart';

part 'locale_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  /// The stored choice, or on a first launch the device's own language list
  /// (on a phone, the phone's language; on the web, the browser's), which is
  /// what the start screen's selector then shows (#172).
  @override
  Locale build() {
    final storage = ref.watch(settingsStorageProvider);
    final device = WidgetsBinding.instance.platformDispatcher.locales;
    return Locale(storage.initUserLanguage(
      preferredLanguageCodes: device.map((locale) => locale.languageCode),
    ));
  }

  Future<void> setLanguage(String languageCode) async {
    final storage = ref.read(settingsStorageProvider);
    final success = await storage.writeUserLanguage(languageCode);
    if (success) {
      state = Locale(languageCode);
    }
  }
}
