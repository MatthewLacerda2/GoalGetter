//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GoalCreationFollowUpQuestionsResponse {
  /// Returns a new [GoalCreationFollowUpQuestionsResponse] instance.
  GoalCreationFollowUpQuestionsResponse({
    required this.originalPrompt,
    this.questions = const [],
  });

  /// The user's declaration of their goal
  String originalPrompt;

  /// The questions to ask the user to understand their goal
  List<String> questions;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GoalCreationFollowUpQuestionsResponse &&
    other.originalPrompt == originalPrompt &&
    _deepEquality.equals(other.questions, questions);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (originalPrompt.hashCode) +
    (questions.hashCode);

  @override
  String toString() => 'GoalCreationFollowUpQuestionsResponse[originalPrompt=$originalPrompt, questions=$questions]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'original_prompt'] = this.originalPrompt;
      json[r'questions'] = this.questions;
    return json;
  }

  /// Returns a new [GoalCreationFollowUpQuestionsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GoalCreationFollowUpQuestionsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GoalCreationFollowUpQuestionsResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GoalCreationFollowUpQuestionsResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GoalCreationFollowUpQuestionsResponse(
        originalPrompt: mapValueOfType<String>(json, r'original_prompt')!,
        questions: json[r'questions'] is Iterable
            ? (json[r'questions'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<GoalCreationFollowUpQuestionsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GoalCreationFollowUpQuestionsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GoalCreationFollowUpQuestionsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GoalCreationFollowUpQuestionsResponse> mapFromJson(dynamic json) {
    final map = <String, GoalCreationFollowUpQuestionsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GoalCreationFollowUpQuestionsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GoalCreationFollowUpQuestionsResponse-objects as value to a dart map
  static Map<String, List<GoalCreationFollowUpQuestionsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GoalCreationFollowUpQuestionsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GoalCreationFollowUpQuestionsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'original_prompt',
    'questions',
  };
}

