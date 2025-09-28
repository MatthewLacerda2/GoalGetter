//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ObjectiveNote {
  /// Returns a new [ObjectiveNote] instance.
  ObjectiveNote({
    required this.id,
    required this.title,
    required this.info,
    required this.isFavorited,
    required this.createdAt,
  });

  String id;

  String title;

  String info;

  bool isFavorited;

  DateTime createdAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ObjectiveNote &&
    other.id == id &&
    other.title == title &&
    other.info == info &&
    other.isFavorited == isFavorited &&
    other.createdAt == createdAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (title.hashCode) +
    (info.hashCode) +
    (isFavorited.hashCode) +
    (createdAt.hashCode);

  @override
  String toString() => 'ObjectiveNote[id=$id, title=$title, info=$info, isFavorited=$isFavorited, createdAt=$createdAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'title'] = this.title;
      json[r'info'] = this.info;
      json[r'is_favorited'] = this.isFavorited;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [ObjectiveNote] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ObjectiveNote? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ObjectiveNote[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ObjectiveNote[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ObjectiveNote(
        id: mapValueOfType<String>(json, r'id')!,
        title: mapValueOfType<String>(json, r'title')!,
        info: mapValueOfType<String>(json, r'info')!,
        isFavorited: mapValueOfType<bool>(json, r'is_favorited')!,
        createdAt: mapDateTime(json, r'created_at', r'')!,
      );
    }
    return null;
  }

  static List<ObjectiveNote> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ObjectiveNote>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ObjectiveNote.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ObjectiveNote> mapFromJson(dynamic json) {
    final map = <String, ObjectiveNote>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ObjectiveNote.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ObjectiveNote-objects as value to a dart map
  static Map<String, List<ObjectiveNote>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ObjectiveNote>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ObjectiveNote.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'title',
    'info',
    'is_favorited',
    'created_at',
  };
}

