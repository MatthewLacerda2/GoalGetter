import 'dart:convert';
import 'dart:io';

import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_route.dart';

import 'schema_check.dart';

/// The backend's API as `make back-build` last wrote it (`backend/openapi.json`,
/// #213). Read from disk, so a test fails the moment the backend's committed
/// API and the app's calls part ways — `flutter test` runs in `frontend/`.
final openApi = OpenApiSnapshot(
  jsonDecode(File('../backend/openapi.json').readAsStringSync())
      as Map<String, dynamic>,
);

class OpenApiSnapshot {
  OpenApiSnapshot(this._doc);

  final Map<String, dynamic> _doc;

  Map<String, dynamic> get _paths => _doc['paths'] as Map<String, dynamic>;

  Map<String, dynamic> get _schemas =>
      (_doc['components'] as Map<String, dynamic>)['schemas']
          as Map<String, dynamic>;

  /// [route]'s operation, or null when the backend has no such method on
  /// that path.
  Map<String, dynamic>? operation(ApiRoute route) {
    final item = _paths['${ApiClient.apiPrefix}${route.template}'];
    return (item as Map<String, dynamic>?)?[route.method.toLowerCase()]
        as Map<String, dynamic>?;
  }

  /// The values of the string enum named [name] under `components/schemas`
  /// — how a Dart enum mirroring a backend one is checked against it.
  List<String> schemaEnum(String name) {
    final schema = _schemas[name] as Map<String, dynamic>?;
    if (schema == null) throw ArgumentError('no schema named $name');
    return (schema['enum'] as List<dynamic>).cast<String>();
  }

  /// Why [body], answered by [route] with [status], is not what the backend
  /// sends; empty when it is. A 2xx the backend does not declare is itself
  /// an error. A non-2xx it does not declare is not checked: the backend
  /// documents no error bodies yet, and when it does (#214) the same call
  /// checks them.
  List<String> replyErrors(ApiRoute route, int status, String body) {
    final op = operation(route);
    if (op == null) return ['${route.method} ${route.template} is not served'];
    final responses = op['responses'] as Map<String, dynamic>;
    final response = responses['$status'] as Map<String, dynamic>?;
    final ok = status >= 200 && status < 300;
    if (response == null) {
      if (!ok) return const [];
      final answers = responses.keys.join(', ');
      final error = '${route.method} ${route.template} never answers '
          '$status; it answers $answers';
      return [error];
    }
    final content = response['content'] as Map<String, dynamic>?;
    final json = content?['application/json'] as Map<String, dynamic>?;
    if (json == null) {
      return body.isEmpty ? const [] : ['$status has no body, got "$body"'];
    }
    final Object? value;
    try {
      value = jsonDecode(body);
    } on FormatException catch (e) {
      return ['not JSON: $e'];
    }
    return schemaErrors(value, json['schema'] as Map<String, dynamic>, _ref);
  }

  /// The route whose template [method] and [path] (under `/api/v1`, no
  /// query) fill, or null when none does.
  static ApiRoute? routeOf(String method, String path) {
    for (final route in ApiRoute.values) {
      if (route.method == method && route.template == path) return route;
    }
    final segments = path.split('/');
    for (final route in ApiRoute.values) {
      final template = route.template.split('/');
      if (route.method != method || template.length != segments.length) {
        continue;
      }
      var fits = true;
      for (var i = 0; i < template.length && fits; i++) {
        fits = template[i] == segments[i] ||
            (template[i].startsWith('{') && segments[i].isNotEmpty);
      }
      if (fits) return route;
    }
    return null;
  }

  Map<String, dynamic> _ref(String ref) {
    const prefix = '#/components/schemas/';
    if (!ref.startsWith(prefix)) throw ArgumentError('unsupported \$ref $ref');
    return _schemas[ref.substring(prefix.length)] as Map<String, dynamic>;
  }
}
