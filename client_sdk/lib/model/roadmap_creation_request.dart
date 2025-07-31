//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RoadmapCreationRequest {
  /// Returns a new [RoadmapCreationRequest] instance.
  RoadmapCreationRequest({
    required this.prompt,
    this.questionsAnswers = const [],
  });

  /// The user's declaration of their goal
  String prompt;

  /// The questions and answers to understand the user's goal
  List<FollowUpQuestionsAndAnswers> questionsAnswers;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RoadmapCreationRequest &&
    other.prompt == prompt &&
    _deepEquality.equals(other.questionsAnswers, questionsAnswers);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (prompt.hashCode) +
    (questionsAnswers.hashCode);

  @override
  String toString() => 'RoadmapCreationRequest[prompt=$prompt, questionsAnswers=$questionsAnswers]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'prompt'] = this.prompt;
      json[r'questions_answers'] = this.questionsAnswers;
    return json;
  }

  /// Returns a new [RoadmapCreationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RoadmapCreationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "RoadmapCreationRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "RoadmapCreationRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RoadmapCreationRequest(
        prompt: mapValueOfType<String>(json, r'prompt')!,
        questionsAnswers: FollowUpQuestionsAndAnswers.listFromJson(json[r'questions_answers']),
      );
    }
    return null;
  }

  static List<RoadmapCreationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoadmapCreationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoadmapCreationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RoadmapCreationRequest> mapFromJson(dynamic json) {
    final map = <String, RoadmapCreationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RoadmapCreationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RoadmapCreationRequest-objects as value to a dart map
  static Map<String, List<RoadmapCreationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<RoadmapCreationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RoadmapCreationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'prompt',
    'questions_answers',
  };
}

