//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StreakDayResponse {
  /// Returns a new [StreakDayResponse] instance.
  StreakDayResponse({
    required this.id,
    required this.dateTime,
  });

  String id;

  DateTime dateTime;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StreakDayResponse &&
    other.id == id &&
    other.dateTime == dateTime;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (dateTime.hashCode);

  @override
  String toString() => 'StreakDayResponse[id=$id, dateTime=$dateTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'date_time'] = this.dateTime.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [StreakDayResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StreakDayResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "StreakDayResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "StreakDayResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StreakDayResponse(
        id: mapValueOfType<String>(json, r'id')!,
        dateTime: mapDateTime(json, r'date_time', r'')!,
      );
    }
    return null;
  }

  static List<StreakDayResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StreakDayResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StreakDayResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StreakDayResponse> mapFromJson(dynamic json) {
    final map = <String, StreakDayResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StreakDayResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StreakDayResponse-objects as value to a dart map
  static Map<String, List<StreakDayResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StreakDayResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StreakDayResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'date_time',
  };
}

