//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RoadmapInitiationRequest {
  /// Returns a new [RoadmapInitiationRequest] instance.
  RoadmapInitiationRequest({
    required this.promptHint,
    required this.prompt,
  });

  /// A hint for the user to properly describe the goal
  String promptHint;

  /// The user's declaration of their goal
  String prompt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoadmapInitiationRequest &&
    other.promptHint == promptHint &&
    other.prompt == prompt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (promptHint.hashCode) +
    (prompt.hashCode);

  @override
  String toString() => 'RoadmapInitiationRequest[promptHint=$promptHint, prompt=$prompt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'prompt_hint'] = this.promptHint;
      json[r'prompt'] = this.prompt;
    return json;
  }

  /// Returns a new [RoadmapInitiationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoadmapInitiationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoadmapInitiationRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoadmapInitiationRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoadmapInitiationRequest(
        promptHint: mapValueOfType<String>(json, r'prompt_hint')!,
        prompt: mapValueOfType<String>(json, r'prompt')!,
      );
    }
    return null;
  }

  static List<RoadmapInitiationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoadmapInitiationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoadmapInitiationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoadmapInitiationRequest> mapFromJson(dynamic json) {
    final map = <String, RoadmapInitiationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoadmapInitiationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoadmapInitiationRequest-objects as value to a dart map
  static Map<String, List<RoadmapInitiationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoadmapInitiationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoadmapInitiationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'prompt_hint',
    'prompt',
  };
}

