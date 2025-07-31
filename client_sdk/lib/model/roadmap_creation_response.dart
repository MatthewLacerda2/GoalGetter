//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RoadmapCreationResponse {
  /// Returns a new [RoadmapCreationResponse] instance.
  RoadmapCreationResponse({
    this.steps = const [],
    this.notes = const [],
  });

  /// The steps to achieve the goal
  List<Step> steps;

  /// The notes to help the user achieve the goal
  List<String> notes;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoadmapCreationResponse &&
    _deepEquality.equals(other.steps, steps) &&
    _deepEquality.equals(other.notes, notes);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (steps.hashCode) +
    (notes.hashCode);

  @override
  String toString() => 'RoadmapCreationResponse[steps=$steps, notes=$notes]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'steps'] = this.steps;
      json[r'notes'] = this.notes;
    return json;
  }

  /// Returns a new [RoadmapCreationResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoadmapCreationResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoadmapCreationResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoadmapCreationResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoadmapCreationResponse(
        steps: Step.listFromJson(json[r'steps']),
        notes: json[r'notes'] is Iterable
            ? (json[r'notes'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<RoadmapCreationResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoadmapCreationResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoadmapCreationResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoadmapCreationResponse> mapFromJson(dynamic json) {
    final map = <String, RoadmapCreationResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoadmapCreationResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoadmapCreationResponse-objects as value to a dart map
  static Map<String, List<RoadmapCreationResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoadmapCreationResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoadmapCreationResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'steps',
    'notes',
  };
}

