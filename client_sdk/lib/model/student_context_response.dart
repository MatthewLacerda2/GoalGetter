//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StudentContextResponse {
  /// Returns a new [StudentContextResponse] instance.
  StudentContextResponse({
    this.contexts = const [],
  });

  List<StudentContextItem> contexts;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StudentContextResponse &&
    _deepEquality.equals(other.contexts, contexts);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (contexts.hashCode);

  @override
  String toString() => 'StudentContextResponse[contexts=$contexts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'contexts'] = this.contexts;
    return json;
  }

  /// Returns a new [StudentContextResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StudentContextResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "StudentContextResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "StudentContextResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StudentContextResponse(
        contexts: StudentContextItem.listFromJson(json[r'contexts']),
      );
    }
    return null;
  }

  static List<StudentContextResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StudentContextResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StudentContextResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StudentContextResponse> mapFromJson(dynamic json) {
    final map = <String, StudentContextResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StudentContextResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StudentContextResponse-objects as value to a dart map
  static Map<String, List<StudentContextResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StudentContextResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StudentContextResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'contexts',
  };
}

