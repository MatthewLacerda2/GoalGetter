import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:http/testing.dart';

import 'openapi_snapshot.dart';

/// A [MockClient] whose every answer is checked against the backend's
/// committed API (#213): a fixture the backend could not have sent — a
/// field renamed, missing or invented, a wrong type, a status the route never
/// answers — fails the test that served it.
///
/// Every fake backend in the suite answers through this, so a hand-typed
/// fixture is checked where it is used, without being listed anywhere.
/// [malformed] names the `'<METHOD> <path>'` keys a test answers wrongly on
/// purpose (to see the app survive it); those alone go unchecked.
///
/// The check fails the test at tear-down rather than throwing here: a throw
/// from the transport would reach the app as a `ServerUnreachable`, and a
/// screen that handles that would pass.
MockClient contractClient(
  MockClientHandler handler, {
  Set<String> malformed = const {},
}) {
  final violations = <String>[];
  addTearDown(() {
    if (violations.isNotEmpty) {
      fail('The fake backend answered what the real one cannot '
          '(backend/openapi.json):\n${violations.join('\n')}');
    }
  });
  return MockClient((request) async {
    final response = await handler(request);
    final path = request.url.path.replaceFirst(ApiClient.apiPrefix, '');
    final key = '${request.method} $path';
    if (malformed.contains(key)) return response;
    final route = OpenApiSnapshot.routeOf(request.method, path);
    if (route == null) {
      violations.add('$key: no ApiRoute has this path');
    } else if (!route.devOnly) {
      final errors =
          openApi.replyErrors(route, response.statusCode, response.body);
      violations.addAll(errors.map((e) => '$key ${response.statusCode}: $e'));
    }
    return response;
  });
}
