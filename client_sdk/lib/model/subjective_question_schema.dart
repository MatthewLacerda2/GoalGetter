//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SubjectiveQuestionSchema {
  /// Returns a new [SubjectiveQuestionSchema] instance.
  SubjectiveQuestionSchema({
    required this.id,
    required this.question,
  });

  String id;

  String question;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SubjectiveQuestionSchema &&
    other.id == id &&
    other.question == question;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (question.hashCode);

  @override
  String toString() => 'SubjectiveQuestionSchema[id=$id, question=$question]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'question'] = this.question;
    return json;
  }

  /// Returns a new [SubjectiveQuestionSchema] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SubjectiveQuestionSchema? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SubjectiveQuestionSchema[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SubjectiveQuestionSchema[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SubjectiveQuestionSchema(
        id: mapValueOfType<String>(json, r'id')!,
        question: mapValueOfType<String>(json, r'question')!,
      );
    }
    return null;
  }

  static List<SubjectiveQuestionSchema> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SubjectiveQuestionSchema>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SubjectiveQuestionSchema.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SubjectiveQuestionSchema> mapFromJson(dynamic json) {
    final map = <String, SubjectiveQuestionSchema>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SubjectiveQuestionSchema.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SubjectiveQuestionSchema-objects as value to a dart map
  static Map<String, List<SubjectiveQuestionSchema>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SubjectiveQuestionSchema>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SubjectiveQuestionSchema.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'question',
  };
}

