//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StudentResponse {
  /// Returns a new [StudentResponse] instance.
  StudentResponse({
    required this.id,
    required this.googleId,
    required this.email,
    required this.name,
  });

  String id;

  String googleId;

  String email;

  String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StudentResponse &&
    other.id == id &&
    other.googleId == googleId &&
    other.email == email &&
    other.name == name;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (googleId.hashCode) +
    (email.hashCode) +
    (name.hashCode);

  @override
  String toString() => 'StudentResponse[id=$id, googleId=$googleId, email=$email, name=$name]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'google_id'] = this.googleId;
      json[r'email'] = this.email;
      json[r'name'] = this.name;
    return json;
  }

  /// Returns a new [StudentResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StudentResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "StudentResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "StudentResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StudentResponse(
        id: mapValueOfType<String>(json, r'id')!,
        googleId: mapValueOfType<String>(json, r'google_id')!,
        email: mapValueOfType<String>(json, r'email')!,
        name: mapValueOfType<String>(json, r'name')!,
      );
    }
    return null;
  }

  static List<StudentResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StudentResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StudentResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StudentResponse> mapFromJson(dynamic json) {
    final map = <String, StudentResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StudentResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StudentResponse-objects as value to a dart map
  static Map<String, List<StudentResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StudentResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StudentResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'google_id',
    'email',
    'name',
  };
}

