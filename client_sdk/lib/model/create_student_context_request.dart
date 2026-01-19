//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateStudentContextRequest {
  /// Returns a new [CreateStudentContextRequest] instance.
  CreateStudentContextRequest({
    required this.context,
  });

  String context;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateStudentContextRequest &&
    other.context == context;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (context.hashCode);

  @override
  String toString() => 'CreateStudentContextRequest[context=$context]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'context'] = this.context;
    return json;
  }

  /// Returns a new [CreateStudentContextRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateStudentContextRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateStudentContextRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateStudentContextRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateStudentContextRequest(
        context: mapValueOfType<String>(json, r'context')!,
      );
    }
    return null;
  }

  static List<CreateStudentContextRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateStudentContextRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateStudentContextRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateStudentContextRequest> mapFromJson(dynamic json) {
    final map = <String, CreateStudentContextRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateStudentContextRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateStudentContextRequest-objects as value to a dart map
  static Map<String, List<CreateStudentContextRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateStudentContextRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateStudentContextRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'context',
  };
}

