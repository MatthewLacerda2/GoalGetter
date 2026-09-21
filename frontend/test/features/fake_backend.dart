import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A canned answer: status and JSON body.
typedef Reply = (int, String);

/// A backend that answers `'<METHOD> <path>'` (path under /api/v1) from
/// [replies], and records every request it got. A route may hold several
/// replies, handed out in order (the last one repeats).
class FakeBackend {
  FakeBackend(Map<String, List<Reply>> replies) : _replies = replies;

  final Map<String, List<Reply>> _replies;
  final List<String> calls = [];
  late SettingsStorage storage;
  late ApiClient api;

  Future<void> start([Map<String, Object> stored = const {}]) async {
    SharedPreferences.setMockInitialValues({'access_token': 'a', ...stored});
    storage = SettingsStorage(await SharedPreferences.getInstance());
    api = ApiClient(
      httpClient: MockClient((request) async {
        final key =
            '${request.method} ${request.url.path.replaceFirst('/api/v1', '')}';
        calls.add(key);
        final queue = _replies[key];
        if (queue == null) return http.Response('{"detail": "no route"}', 599);
        final (status, body) = queue.length > 1 ? queue.removeAt(0) : queue[0];
        return http.Response(body, status);
      }),
      storage: storage,
      baseUrl: 'http://api.test',
    );
  }

  List<Override> get overrides => [
        settingsStorageProvider.overrideWithValue(storage),
        apiClientProvider.overrideWithValue(api),
      ];
}

/// Pumps [initial] in a router that also has placeholder screens for the
/// routes a goal action lands on, each showing its own path.
Future<void> pumpRouted(
  WidgetTester tester,
  FakeBackend backend,
  List<RouteBase> routes, {
  required String initial,
}) async {
  Widget landing(String path) => Scaffold(body: Text('landed $path'));
  final router = GoRouter(initialLocation: initial, routes: [
    ...routes,
    for (final path in ['/home', '/onboarding/goal'])
      GoRoute(path: path, builder: (_, __) => landing(path)),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: backend.overrides,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
}

/// One item of GET /goals, as JSON.
String goalJson(String id, {bool active = false, String name = 'Learn Go'}) =>
    '{"id": "$id", "name": "$name", "description": "About **$name**",'
    ' "current_elo": 1100, "is_active": $active,'
    ' "created_at": "2026-09-01T10:00:00Z",'
    ' "updated_at": "2026-09-20T10:00:00Z"}';
