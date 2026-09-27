/// A JSON Schema check for the subset the backend's OpenAPI uses (Pydantic's
/// output), written here rather than pulled in as a package: it is small,
/// and it can be stricter than the standard where a fixture needs it to be.
///
/// Where it departs from JSON Schema, on purpose:
/// - An object may not carry a key its schema does not list. Pydantic emits
///   no `additionalProperties`, so the standard would accept any extra key —
///   and a fixture inventing a field the backend never sends is the drift
///   this check exists to catch.
/// - `format` is checked for `date-time` only, because the app parses those
///   (`DateTime.parse`). A `uuid` stays an annotation: the app treats ids as
///   opaque strings, so fixtures may keep ids like `g1`.
/// - A keyword it does not know fails the check instead of passing unread,
///   so a new shape in the backend's schema is taught here, never skipped.
library;

/// The ways [value] breaks [schema], each prefixed by where (`$.questions[0]`).
/// Empty when it conforms. [resolve] turns a `$ref` into its schema.
List<String> schemaErrors(
  Object? value,
  Map<String, dynamic> schema,
  Map<String, dynamic> Function(String ref) resolve, {
  String at = r'$',
}) {
  final errors = <String>[];
  _check(value, schema, resolve, at, errors);
  return errors;
}

/// Keywords that describe a schema without constraining it.
const _annotations = {'title', 'description', 'default', 'examples'};

const _known = {
  ..._annotations,
  r'$ref', 'anyOf', 'enum', 'format', 'items', 'maxItems', 'minItems',
  'maxLength', 'minLength', 'maximum', 'minimum', 'properties', 'required',
  'type',
};

void _check(
  Object? value,
  Map<String, dynamic> schema,
  Map<String, dynamic> Function(String) resolve,
  String at,
  List<String> errors,
) {
  final unknown = schema.keys.where((k) => !_known.contains(k));
  if (unknown.isNotEmpty) {
    errors.add('$at: the schema uses $unknown, which schema_check.dart '
        'does not know yet');
    return;
  }
  if (schema[r'$ref'] case final String ref) {
    _check(value, resolve(ref), resolve, at, errors);
    return;
  }
  if (schema['anyOf'] case final List<dynamic> options) {
    final fits = options.any((o) => schemaErrors(
          value,
          o as Map<String, dynamic>,
          resolve,
          at: at,
        ).isEmpty);
    if (!fits) errors.add('$at: ${_show(value)} fits none of $options');
    return;
  }
  if (schema['enum'] case final List<dynamic> allowed
      when !allowed.contains(value)) {
    errors.add('$at: ${_show(value)} is not one of $allowed');
    return;
  }
  if (schema['type'] case final String type) {
    if (!_isType(value, type)) {
      errors.add('$at: expected $type, got ${_show(value)}');
      return;
    }
  }
  _checkBounds(value, schema, at, errors);
  if (value is Map<String, dynamic>) {
    _checkObject(value, schema, resolve, at, errors);
  }
  if (value is List && schema['items'] is Map<String, dynamic>) {
    for (var i = 0; i < value.length; i++) {
      _check(value[i], schema['items'] as Map<String, dynamic>, resolve,
          '$at[$i]', errors);
    }
  }
}

void _checkObject(
  Map<String, dynamic> value,
  Map<String, dynamic> schema,
  Map<String, dynamic> Function(String) resolve,
  String at,
  List<String> errors,
) {
  final properties =
      (schema['properties'] as Map<String, dynamic>?) ?? const {};
  for (final key in (schema['required'] as List<dynamic>?) ?? const []) {
    if (!value.containsKey(key)) errors.add('$at: missing "$key"');
  }
  for (final MapEntry(:key, value: field) in value.entries) {
    final property = properties[key];
    if (property == null) {
      errors.add('$at: "$key" is not a field of this response');
    } else {
      _check(field, property as Map<String, dynamic>, resolve, '$at.$key',
          errors);
    }
  }
}

void _checkBounds(
  Object? value,
  Map<String, dynamic> schema,
  String at,
  List<String> errors,
) {
  void bound(String keyword, num actual, {required bool isMax}) {
    final limit = schema[keyword] as num?;
    if (limit == null) return;
    if (isMax ? actual > limit : actual < limit) {
      errors.add('$at: $keyword is $limit, got $actual');
    }
  }

  switch (value) {
    case final String s:
      bound('maxLength', s.length, isMax: true);
      bound('minLength', s.length, isMax: false);
      if (schema['format'] == 'date-time' && DateTime.tryParse(s) == null) {
        errors.add('$at: "$s" is not a date-time');
      }
    case final List<dynamic> l:
      bound('maxItems', l.length, isMax: true);
      bound('minItems', l.length, isMax: false);
    case final num n:
      bound('maximum', n, isMax: true);
      bound('minimum', n, isMax: false);
  }
}

bool _isType(Object? value, String type) => switch (type) {
      'string' => value is String,
      'integer' => value is int || (value is double && value % 1 == 0),
      'number' => value is num,
      'boolean' => value is bool,
      'array' => value is List,
      'object' => value is Map,
      'null' => value == null,
      _ => false,
    };

String _show(Object? value) => value is String ? '"$value"' : '$value';
