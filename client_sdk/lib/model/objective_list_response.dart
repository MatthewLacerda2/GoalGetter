//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ObjectiveListResponse {
  /// Returns a new [ObjectiveListResponse] instance.
  ObjectiveListResponse({
    this.objectiveList = const [],
  });

  List<ObjectiveItem> objectiveList;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ObjectiveListResponse &&
    _deepEquality.equals(other.objectiveList, objectiveList);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (objectiveList.hashCode);

  @override
  String toString() => 'ObjectiveListResponse[objectiveList=$objectiveList]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'objective_list'] = this.objectiveList;
    return json;
  }

  /// Returns a new [ObjectiveListResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ObjectiveListResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ObjectiveListResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ObjectiveListResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ObjectiveListResponse(
        objectiveList: ObjectiveItem.listFromJson(json[r'objective_list']),
      );
    }
    return null;
  }

  static List<ObjectiveListResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ObjectiveListResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ObjectiveListResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ObjectiveListResponse> mapFromJson(dynamic json) {
    final map = <String, ObjectiveListResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ObjectiveListResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ObjectiveListResponse-objects as value to a dart map
  static Map<String, List<ObjectiveListResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ObjectiveListResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ObjectiveListResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'objective_list',
  };
}

