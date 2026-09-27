import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/app/router/app_router.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/services/session.dart';
import 'package:goal_getter/core/services/shared_preferences_provider.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// The real app — its router, its route table, its providers — with only the
/// network and Google replaced.

/// Google, without its plugin: the start screen renders its button.
class _NoGoogle extends AuthService {
  _NoGoogle({
    required super.api,
    required super.storage,
    super.onSessionChanged,
  });

  @override
  Future<void> ensureInitialized() async {}

  @override
  Stream<String> googleTokens() => const Stream.empty();
}

/// Launches [GoalGetterApp] over [stored] and [backend], and lets it settle.
Future<(GoRouter, SharedPreferences)> launchApp(
  WidgetTester tester,
  http.Client backend, {
  Map<String, Object> stored = const {},
}) async {
  SharedPreferences.setMockInitialValues({'user_language': 'en', ...stored});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    retry: noAutomaticRetry,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      httpClientProvider.overrideWithValue(backend),
      authServiceProvider.overrideWith((ref) => _NoGoogle(
            api: ref.watch(apiClientProvider),
            storage: ref.watch(settingsStorageProvider),
            onSessionChanged: () => ref.read(signedInProvider.notifier).sync(),
          )),
    ],
    child: const GoalGetterApp(),
  ));
  await tester.pumpAndSettle();
  final container =
      ProviderScope.containerOf(tester.element(find.byType(GoalGetterApp)));
  return (container.read(goRouterProvider), prefs);
}

/// Where the router ended up.
String routerAt(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;
