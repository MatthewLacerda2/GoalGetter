//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SubjectiveQuestionEvaluationRequest {
  /// Returns a new [SubjectiveQuestionEvaluationRequest] instance.
  SubjectiveQuestionEvaluationRequest({
    required this.questionId,
    required this.question,
    required this.studentAnswer,
    required this.secondsSpent,
  });

  String questionId;

  String question;

  String studentAnswer;

  int secondsSpent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubjectiveQuestionEvaluationRequest &&
    other.questionId == questionId &&
    other.question == question &&
    other.studentAnswer == studentAnswer &&
    other.secondsSpent == secondsSpent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (questionId.hashCode) +
    (question.hashCode) +
    (studentAnswer.hashCode) +
    (secondsSpent.hashCode);

  @override
  String toString() => 'SubjectiveQuestionEvaluationRequest[questionId=$questionId, question=$question, studentAnswer=$studentAnswer, secondsSpent=$secondsSpent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'question_id'] = this.questionId;
      json[r'question'] = this.question;
      json[r'student_answer'] = this.studentAnswer;
      json[r'seconds_spent'] = this.secondsSpent;
    return json;
  }

  /// Returns a new [SubjectiveQuestionEvaluationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubjectiveQuestionEvaluationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubjectiveQuestionEvaluationRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubjectiveQuestionEvaluationRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubjectiveQuestionEvaluationRequest(
        questionId: mapValueOfType<String>(json, r'question_id')!,
        question: mapValueOfType<String>(json, r'question')!,
        studentAnswer: mapValueOfType<String>(json, r'student_answer')!,
        secondsSpent: mapValueOfType<int>(json, r'seconds_spent')!,
      );
    }
    return null;
  }

  static List<SubjectiveQuestionEvaluationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubjectiveQuestionEvaluationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubjectiveQuestionEvaluationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubjectiveQuestionEvaluationRequest> mapFromJson(dynamic json) {
    final map = <String, SubjectiveQuestionEvaluationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubjectiveQuestionEvaluationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubjectiveQuestionEvaluationRequest-objects as value to a dart map
  static Map<String, List<SubjectiveQuestionEvaluationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubjectiveQuestionEvaluationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubjectiveQuestionEvaluationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'question_id',
    'question',
    'student_answer',
    'seconds_spent',
  };
}

