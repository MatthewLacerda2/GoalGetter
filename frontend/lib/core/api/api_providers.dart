import 'package:goal_getter/app/router/app_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_providers.g.dart';

/// The transport under [ApiClient]. Tests override it with
/// `package:http/testing.dart`'s `MockClient`.
@Riverpod(keepAlive: true)
http.Client httpClient(HttpClientRef ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// Kept alive on purpose: the client owns the in-flight refresh that every
/// concurrent 401 shares, so a rebuilt client would refresh twice.
@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient(
    httpClient: ref.watch(httpClientProvider),
    storage: ref.watch(settingsStorageProvider),
    baseUrl: resolveBaseUrl(AppConfig.baseUrl),
    onSessionExpired: () => ref.read(goRouterProvider).go(AppRoutes.start),
  );
}
