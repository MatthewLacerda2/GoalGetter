//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FollowUpQuestionsAndAnswers {
  /// Returns a new [FollowUpQuestionsAndAnswers] instance.
  FollowUpQuestionsAndAnswers({
    required this.question,
    required this.answer,
  });

  /// A question to understand the user's goal
  String question;

  /// The user's answer to the question
  String answer;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FollowUpQuestionsAndAnswers &&
    other.question == question &&
    other.answer == answer;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (question.hashCode) +
    (answer.hashCode);

  @override
  String toString() => 'FollowUpQuestionsAndAnswers[question=$question, answer=$answer]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'question'] = this.question;
      json[r'answer'] = this.answer;
    return json;
  }

  /// Returns a new [FollowUpQuestionsAndAnswers] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FollowUpQuestionsAndAnswers? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FollowUpQuestionsAndAnswers[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FollowUpQuestionsAndAnswers[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FollowUpQuestionsAndAnswers(
        question: mapValueOfType<String>(json, r'question')!,
        answer: mapValueOfType<String>(json, r'answer')!,
      );
    }
    return null;
  }

  static List<FollowUpQuestionsAndAnswers> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FollowUpQuestionsAndAnswers>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FollowUpQuestionsAndAnswers.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FollowUpQuestionsAndAnswers> mapFromJson(dynamic json) {
    final map = <String, FollowUpQuestionsAndAnswers>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FollowUpQuestionsAndAnswers.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FollowUpQuestionsAndAnswers-objects as value to a dart map
  static Map<String, List<FollowUpQuestionsAndAnswers>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FollowUpQuestionsAndAnswers>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FollowUpQuestionsAndAnswers.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'question',
    'answer',
  };
}

