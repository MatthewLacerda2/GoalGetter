//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MultipleChoiceQuestionResponse {
  /// Returns a new [MultipleChoiceQuestionResponse] instance.
  MultipleChoiceQuestionResponse({
    required this.id,
    required this.question,
    this.choices = const [],
    required this.correctAnswerIndex,
  });

  String id;

  String question;

  List<String> choices;

  int correctAnswerIndex;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MultipleChoiceQuestionResponse &&
    other.id == id &&
    other.question == question &&
    _deepEquality.equals(other.choices, choices) &&
    other.correctAnswerIndex == correctAnswerIndex;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (question.hashCode) +
    (choices.hashCode) +
    (correctAnswerIndex.hashCode);

  @override
  String toString() => 'MultipleChoiceQuestionResponse[id=$id, question=$question, choices=$choices, correctAnswerIndex=$correctAnswerIndex]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'question'] = this.question;
      json[r'choices'] = this.choices;
      json[r'correct_answer_index'] = this.correctAnswerIndex;
    return json;
  }

  /// Returns a new [MultipleChoiceQuestionResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MultipleChoiceQuestionResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MultipleChoiceQuestionResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MultipleChoiceQuestionResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MultipleChoiceQuestionResponse(
        id: mapValueOfType<String>(json, r'id')!,
        question: mapValueOfType<String>(json, r'question')!,
        choices: json[r'choices'] is Iterable
            ? (json[r'choices'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        correctAnswerIndex: mapValueOfType<int>(json, r'correct_answer_index')!,
      );
    }
    return null;
  }

  static List<MultipleChoiceQuestionResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MultipleChoiceQuestionResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MultipleChoiceQuestionResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MultipleChoiceQuestionResponse> mapFromJson(dynamic json) {
    final map = <String, MultipleChoiceQuestionResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MultipleChoiceQuestionResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MultipleChoiceQuestionResponse-objects as value to a dart map
  static Map<String, List<MultipleChoiceQuestionResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MultipleChoiceQuestionResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MultipleChoiceQuestionResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'question',
    'choices',
    'correct_answer_index',
  };
}

