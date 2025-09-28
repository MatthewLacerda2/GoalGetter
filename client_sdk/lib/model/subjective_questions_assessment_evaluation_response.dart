//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SubjectiveQuestionsAssessmentEvaluationResponse {
  /// Returns a new [SubjectiveQuestionsAssessmentEvaluationResponse] instance.
  SubjectiveQuestionsAssessmentEvaluationResponse({
    required this.llmEvaluation,
    required this.llmInformation,
    required this.llmMetacognition,
    required this.isApproved,
  });

  /// The AI's assessment of the student's overall performance
  String llmEvaluation;

  /// something
  String llmInformation;

  /// The AI's assessment of the student's understanding
  String llmMetacognition;

  /// Was the student's prowess satisfactory?
  bool isApproved;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubjectiveQuestionsAssessmentEvaluationResponse &&
    other.llmEvaluation == llmEvaluation &&
    other.llmInformation == llmInformation &&
    other.llmMetacognition == llmMetacognition &&
    other.isApproved == isApproved;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (llmEvaluation.hashCode) +
    (llmInformation.hashCode) +
    (llmMetacognition.hashCode) +
    (isApproved.hashCode);

  @override
  String toString() => 'SubjectiveQuestionsAssessmentEvaluationResponse[llmEvaluation=$llmEvaluation, llmInformation=$llmInformation, llmMetacognition=$llmMetacognition, isApproved=$isApproved]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'llm_evaluation'] = this.llmEvaluation;
      json[r'llm_information'] = this.llmInformation;
      json[r'llm_metacognition'] = this.llmMetacognition;
      json[r'is_approved'] = this.isApproved;
    return json;
  }

  /// Returns a new [SubjectiveQuestionsAssessmentEvaluationResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubjectiveQuestionsAssessmentEvaluationResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubjectiveQuestionsAssessmentEvaluationResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubjectiveQuestionsAssessmentEvaluationResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubjectiveQuestionsAssessmentEvaluationResponse(
        llmEvaluation: mapValueOfType<String>(json, r'llm_evaluation')!,
        llmInformation: mapValueOfType<String>(json, r'llm_information')!,
        llmMetacognition: mapValueOfType<String>(json, r'llm_metacognition')!,
        isApproved: mapValueOfType<bool>(json, r'is_approved')!,
      );
    }
    return null;
  }

  static List<SubjectiveQuestionsAssessmentEvaluationResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubjectiveQuestionsAssessmentEvaluationResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubjectiveQuestionsAssessmentEvaluationResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubjectiveQuestionsAssessmentEvaluationResponse> mapFromJson(dynamic json) {
    final map = <String, SubjectiveQuestionsAssessmentEvaluationResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubjectiveQuestionsAssessmentEvaluationResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubjectiveQuestionsAssessmentEvaluationResponse-objects as value to a dart map
  static Map<String, List<SubjectiveQuestionsAssessmentEvaluationResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubjectiveQuestionsAssessmentEvaluationResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubjectiveQuestionsAssessmentEvaluationResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'llm_evaluation',
    'llm_information',
    'llm_metacognition',
    'is_approved',
  };
}

