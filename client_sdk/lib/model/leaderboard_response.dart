//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaderboardResponse {
  /// Returns a new [LeaderboardResponse] instance.
  LeaderboardResponse({
    this.students = const [],
  });

  List<LeaderboardItem> students;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaderboardResponse &&
    _deepEquality.equals(other.students, students);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (students.hashCode);

  @override
  String toString() => 'LeaderboardResponse[students=$students]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'students'] = this.students;
    return json;
  }

  /// Returns a new [LeaderboardResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaderboardResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaderboardResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaderboardResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaderboardResponse(
        students: LeaderboardItem.listFromJson(json[r'students']),
      );
    }
    return null;
  }

  static List<LeaderboardResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaderboardResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaderboardResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaderboardResponse> mapFromJson(dynamic json) {
    final map = <String, LeaderboardResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaderboardResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaderboardResponse-objects as value to a dart map
  static Map<String, List<LeaderboardResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaderboardResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaderboardResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'students',
  };
}

