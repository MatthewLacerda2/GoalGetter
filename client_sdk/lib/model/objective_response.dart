//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ObjectiveResponse {
  /// Returns a new [ObjectiveResponse] instance.
  ObjectiveResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.percentageCompleted,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.notes = const [],
  });

  String id;

  String name;

  String description;

  /// How much mastery of the objective does the student have?
  ///
  /// Minimum value: 0.0
  /// Maximum value: 100.0
  num percentageCompleted;

  DateTime createdAt;

  DateTime lastUpdatedAt;

  List<ObjectiveNote> notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ObjectiveResponse &&
    other.id == id &&
    other.name == name &&
    other.description == description &&
    other.percentageCompleted == percentageCompleted &&
    other.createdAt == createdAt &&
    other.lastUpdatedAt == lastUpdatedAt &&
    _deepEquality.equals(other.notes, notes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (name.hashCode) +
    (description.hashCode) +
    (percentageCompleted.hashCode) +
    (createdAt.hashCode) +
    (lastUpdatedAt.hashCode) +
    (notes.hashCode);

  @override
  String toString() => 'ObjectiveResponse[id=$id, name=$name, description=$description, percentageCompleted=$percentageCompleted, createdAt=$createdAt, lastUpdatedAt=$lastUpdatedAt, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'percentage_completed'] = this.percentageCompleted;
      json[r'created_at'] = this.createdAt.toUtc().toIso8601String();
      json[r'last_updated_at'] = this.lastUpdatedAt.toUtc().toIso8601String();
      json[r'notes'] = this.notes;
    return json;
  }

  /// Returns a new [ObjectiveResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ObjectiveResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ObjectiveResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ObjectiveResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ObjectiveResponse(
        id: mapValueOfType<String>(json, r'id')!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        percentageCompleted: num.parse('${json[r'percentage_completed']}'),
        createdAt: mapDateTime(json, r'created_at', r'')!,
        lastUpdatedAt: mapDateTime(json, r'last_updated_at', r'')!,
        notes: ObjectiveNote.listFromJson(json[r'notes']),
      );
    }
    return null;
  }

  static List<ObjectiveResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ObjectiveResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ObjectiveResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ObjectiveResponse> mapFromJson(dynamic json) {
    final map = <String, ObjectiveResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ObjectiveResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ObjectiveResponse-objects as value to a dart map
  static Map<String, List<ObjectiveResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ObjectiveResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ObjectiveResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'name',
    'description',
    'percentage_completed',
    'created_at',
    'last_updated_at',
    'notes',
  };
}

