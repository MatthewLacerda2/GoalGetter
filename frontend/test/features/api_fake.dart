import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A backend that answers `'<METHOD> <path>'` (path under /api/v1) with
/// canned `(status, body)` replies, handed out in order (the last repeats),
/// and records every request's key and body. Unknown routes answer 599.
class ApiFake {
  ApiFake(this.replies);

  final Map<String, List<(int, String)>> replies;
  final List<(String, String)> requests = [];

  int count(String key) => requests.where((r) => r.$1 == key).length;

  /// The providers the features read, over a device holding a session and,
  /// when given, the active goal id.
  Future<List<Override>> overrides({String? goalId = 'g1'}) async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'a',
      if (goalId != null) 'current_goal_id': goalId,
    });
    final storage = SettingsStorage(await SharedPreferences.getInstance());
    final api = ApiClient(
      httpClient: MockClient((request) async {
        final key =
            '${request.method} ${request.url.path.replaceFirst('/api/v1', '')}';
        requests.add((key, request.body));
        final queue = replies[key];
        if (queue == null) return http.Response('{"detail": "no route"}', 599);
        final (status, body) = queue.length > 1 ? queue.removeAt(0) : queue[0];
        return http.Response(body, status);
      }),
      storage: storage,
      baseUrl: 'http://api.test',
    );
    return [
      settingsStorageProvider.overrideWithValue(storage),
      apiClientProvider.overrideWithValue(api),
    ];
  }
}

/// Pumps [screen] in an English MaterialApp over [overrides].
Future<void> pumpScreen(
  WidgetTester tester,
  List<Override> overrides,
  Widget screen,
) async {
  await tester.pumpWidget(ProviderScope(
    retry: noAutomaticRetry,
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
}
