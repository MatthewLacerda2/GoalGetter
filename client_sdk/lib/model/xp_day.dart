//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class XpDay {
  /// Returns a new [XpDay] instance.
  XpDay({
    required this.id,
    required this.xp,
    required this.dateTime,
  });

  String id;

  int xp;

  DateTime dateTime;

  @override
  bool operator ==(Object other) => identical(this, other) || other is XpDay &&
    other.id == id &&
    other.xp == xp &&
    other.dateTime == dateTime;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (xp.hashCode) +
    (dateTime.hashCode);

  @override
  String toString() => 'XpDay[id=$id, xp=$xp, dateTime=$dateTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'xp'] = this.xp;
      json[r'date_time'] = this.dateTime.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [XpDay] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static XpDay? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "XpDay[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "XpDay[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return XpDay(
        id: mapValueOfType<String>(json, r'id')!,
        xp: mapValueOfType<int>(json, r'xp')!,
        dateTime: mapDateTime(json, r'date_time', r'')!,
      );
    }
    return null;
  }

  static List<XpDay> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <XpDay>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = XpDay.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, XpDay> mapFromJson(dynamic json) {
    final map = <String, XpDay>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = XpDay.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of XpDay-objects as value to a dart map
  static Map<String, List<XpDay>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<XpDay>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = XpDay.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'xp',
    'date_time',
  };
}

