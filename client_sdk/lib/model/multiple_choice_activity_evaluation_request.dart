//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class MultipleChoiceActivityEvaluationRequest {
  /// Returns a new [MultipleChoiceActivityEvaluationRequest] instance.
  MultipleChoiceActivityEvaluationRequest({
    this.answers = const [],
  });

  List<MultipleChoiceQuestionAnswer> answers;

  @override
  bool operator ==(Object other) => identical(this, other) || other is MultipleChoiceActivityEvaluationRequest &&
    _deepEquality.equals(other.answers, answers);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (answers.hashCode);

  @override
  String toString() => 'MultipleChoiceActivityEvaluationRequest[answers=$answers]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'answers'] = this.answers;
    return json;
  }

  /// Returns a new [MultipleChoiceActivityEvaluationRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static MultipleChoiceActivityEvaluationRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "MultipleChoiceActivityEvaluationRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "MultipleChoiceActivityEvaluationRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return MultipleChoiceActivityEvaluationRequest(
        answers: MultipleChoiceQuestionAnswer.listFromJson(json[r'answers']),
      );
    }
    return null;
  }

  static List<MultipleChoiceActivityEvaluationRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <MultipleChoiceActivityEvaluationRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = MultipleChoiceActivityEvaluationRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, MultipleChoiceActivityEvaluationRequest> mapFromJson(dynamic json) {
    final map = <String, MultipleChoiceActivityEvaluationRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = MultipleChoiceActivityEvaluationRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of MultipleChoiceActivityEvaluationRequest-objects as value to a dart map
  static Map<String, List<MultipleChoiceActivityEvaluationRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<MultipleChoiceActivityEvaluationRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = MultipleChoiceActivityEvaluationRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'answers',
  };
}

