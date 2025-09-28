//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MultipleChoiceQuestionAnswer {
  /// Returns a new [MultipleChoiceQuestionAnswer] instance.
  MultipleChoiceQuestionAnswer({
    required this.id,
    required this.studentAnswerIndex,
    required this.secondsSpent,
  });

  String id;

  /// The zero-based index of the student's answer
  ///
  /// Minimum value: 0
  /// Maximum value: 4
  int studentAnswerIndex;

  /// Amount of seconds spent in the question
  ///
  /// Minimum value: 2
  /// Maximum value: 3600
  int secondsSpent;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MultipleChoiceQuestionAnswer &&
    other.id == id &&
    other.studentAnswerIndex == studentAnswerIndex &&
    other.secondsSpent == secondsSpent;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (studentAnswerIndex.hashCode) +
    (secondsSpent.hashCode);

  @override
  String toString() => 'MultipleChoiceQuestionAnswer[id=$id, studentAnswerIndex=$studentAnswerIndex, secondsSpent=$secondsSpent]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'student_answer_index'] = this.studentAnswerIndex;
      json[r'seconds_spent'] = this.secondsSpent;
    return json;
  }

  /// Returns a new [MultipleChoiceQuestionAnswer] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MultipleChoiceQuestionAnswer? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MultipleChoiceQuestionAnswer[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MultipleChoiceQuestionAnswer[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MultipleChoiceQuestionAnswer(
        id: mapValueOfType<String>(json, r'id')!,
        studentAnswerIndex: mapValueOfType<int>(json, r'student_answer_index')!,
        secondsSpent: mapValueOfType<int>(json, r'seconds_spent')!,
      );
    }
    return null;
  }

  static List<MultipleChoiceQuestionAnswer> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MultipleChoiceQuestionAnswer>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MultipleChoiceQuestionAnswer.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MultipleChoiceQuestionAnswer> mapFromJson(dynamic json) {
    final map = <String, MultipleChoiceQuestionAnswer>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MultipleChoiceQuestionAnswer.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MultipleChoiceQuestionAnswer-objects as value to a dart map
  static Map<String, List<MultipleChoiceQuestionAnswer>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MultipleChoiceQuestionAnswer>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MultipleChoiceQuestionAnswer.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'student_answer_index',
    'seconds_spent',
  };
}

