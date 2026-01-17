//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GoalListItem {
  /// Returns a new [GoalListItem] instance.
  GoalListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  /// The unique identifier of the goal
  String id;

  /// The name of the goal
  String name;

  /// The description of the goal
  String description;

  /// When the goal was created
  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GoalListItem &&
    other.id == id &&
    other.name == name &&
    other.description == description &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (description.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'GoalListItem[id=$id, name=$name, description=$description, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [GoalListItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GoalListItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GoalListItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GoalListItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GoalListItem(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<GoalListItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GoalListItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GoalListItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GoalListItem> mapFromJson(dynamic json) {
    final map = <String, GoalListItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GoalListItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GoalListItem-objects as value to a dart map
  static Map<String, List<GoalListItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GoalListItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GoalListItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'description',
    'created_at',
  };
}

