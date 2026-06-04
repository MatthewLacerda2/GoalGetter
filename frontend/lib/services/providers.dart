import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/settings_storage.dart';
import 'auth_service.dart';
import 'openapi_client_factory.dart';

/// Provider for SharedPreferences. Must be overridden in main.dart at startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider was not overridden');
});

/// Provider for AuthService singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for OpenApiClientFactory.
final openApiClientFactoryProvider = Provider<OpenApiClientFactory>((ref) {
  final authService = ref.watch(authServiceProvider);
  return OpenApiClientFactory(authService: authService);
});

/// Provider for fetching an authorized ApiClient asynchronously.
final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  final factory = ref.watch(openApiClientFactoryProvider);
  return factory.createAuthorized();
});

/// Notifier that manages the user's language setting.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(String initialLanguageCode) : super(Locale(initialLanguageCode));

  Future<void> setLanguage(String languageCode) async {
    final success = await SettingsStorage.setUserLanguage(languageCode);
    if (success) {
      state = Locale(languageCode);
    }
  }
}

/// Provider for language Locale setting.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final initialLang = SettingsStorage.getUserLanguageSync();
  return LocaleNotifier(initialLang);
});
