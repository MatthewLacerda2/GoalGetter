//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LeaderboardItem {
  /// Returns a new [LeaderboardItem] instance.
  LeaderboardItem({
    required this.name,
    required this.objective,
    required this.xp,
  });

  String name;

  String objective;

  /// Student's overall XP
  ///
  /// Minimum value: 0
  int xp;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LeaderboardItem &&
    other.name == name &&
    other.objective == objective &&
    other.xp == xp;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (name.hashCode) +
    (objective.hashCode) +
    (xp.hashCode);

  @override
  String toString() => 'LeaderboardItem[name=$name, objective=$objective, xp=$xp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'name'] = this.name;
      json[r'objective'] = this.objective;
      json[r'xp'] = this.xp;
    return json;
  }

  /// Returns a new [LeaderboardItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LeaderboardItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LeaderboardItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LeaderboardItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LeaderboardItem(
        name: mapValueOfType<String>(json, r'name')!,
        objective: mapValueOfType<String>(json, r'objective')!,
        xp: mapValueOfType<int>(json, r'xp')!,
      );
    }
    return null;
  }

  static List<LeaderboardItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LeaderboardItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LeaderboardItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LeaderboardItem> mapFromJson(dynamic json) {
    final map = <String, LeaderboardItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LeaderboardItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LeaderboardItem-objects as value to a dart map
  static Map<String, List<LeaderboardItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LeaderboardItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LeaderboardItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'name',
    'objective',
    'xp',
  };
}

