//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlayerAchievementItem {
  /// Returns a new [PlayerAchievementItem] instance.
  PlayerAchievementItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.achievedAt,
  });

  String id;

  String name;

  String description;

  String imageUrl;

  DateTime achievedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlayerAchievementItem &&
    other.id == id &&
    other.name == name &&
    other.description == description &&
    other.imageUrl == imageUrl &&
    other.achievedAt == achievedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (description.hashCode) +
    (imageUrl.hashCode) +
    (achievedAt.hashCode);

  @override
  String toString() => 'PlayerAchievementItem[id=$id, name=$name, description=$description, imageUrl=$imageUrl, achievedAt=$achievedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'image_url'] = this.imageUrl;
      json[r'achieved_at'] = this.achievedAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [PlayerAchievementItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlayerAchievementItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PlayerAchievementItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PlayerAchievementItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PlayerAchievementItem(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        imageUrl: mapValueOfType<String>(json, r'image_url')!,
        achievedAt: mapDateTime(json, r'achieved_at', r'')!,
      );
    }
    return null;
  }

  static List<PlayerAchievementItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlayerAchievementItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlayerAchievementItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlayerAchievementItem> mapFromJson(dynamic json) {
    final map = <String, PlayerAchievementItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlayerAchievementItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlayerAchievementItem-objects as value to a dart map
  static Map<String, List<PlayerAchievementItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlayerAchievementItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlayerAchievementItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'description',
    'image_url',
    'achieved_at',
  };
}

