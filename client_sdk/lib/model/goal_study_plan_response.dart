//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class GoalStudyPlanResponse {
  /// Returns a new [GoalStudyPlanResponse] instance.
  GoalStudyPlanResponse({
    required this.goalName,
    required this.goalDescription,
    required this.firstObjectiveName,
    required this.firstObjectiveDescription,
    this.milestones = const [],
  });

  /// The Goal defined by the Tutor for the user
  String goalName;

  /// The Description of the Goal defined by the Tutor for the user
  String goalDescription;

  /// The First Objective towards the Goal. Defined by the Tutor for the user
  String firstObjectiveName;

  /// The Description of the First Objective towards the Goal. Defined by the Tutor for the user
  String firstObjectiveDescription;

  /// The Milestones towards the Goal. Defined by the Tutor for the user
  List<String> milestones;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GoalStudyPlanResponse &&
    other.goalName == goalName &&
    other.goalDescription == goalDescription &&
    other.firstObjectiveName == firstObjectiveName &&
    other.firstObjectiveDescription == firstObjectiveDescription &&
    _deepEquality.equals(other.milestones, milestones);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (goalName.hashCode) +
    (goalDescription.hashCode) +
    (firstObjectiveName.hashCode) +
    (firstObjectiveDescription.hashCode) +
    (milestones.hashCode);

  @override
  String toString() => 'GoalStudyPlanResponse[goalName=$goalName, goalDescription=$goalDescription, firstObjectiveName=$firstObjectiveName, firstObjectiveDescription=$firstObjectiveDescription, milestones=$milestones]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'goal_name'] = this.goalName;
      json[r'goal_description'] = this.goalDescription;
      json[r'first_objective_name'] = this.firstObjectiveName;
      json[r'first_objective_description'] = this.firstObjectiveDescription;
      json[r'milestones'] = this.milestones;
    return json;
  }

  /// Returns a new [GoalStudyPlanResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static GoalStudyPlanResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "GoalStudyPlanResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "GoalStudyPlanResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return GoalStudyPlanResponse(
        goalName: mapValueOfType<String>(json, r'goal_name')!,
        goalDescription: mapValueOfType<String>(json, r'goal_description')!,
        firstObjectiveName: mapValueOfType<String>(json, r'first_objective_name')!,
        firstObjectiveDescription: mapValueOfType<String>(json, r'first_objective_description')!,
        milestones: json[r'milestones'] is Iterable
            ? (json[r'milestones'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<GoalStudyPlanResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <GoalStudyPlanResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = GoalStudyPlanResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, GoalStudyPlanResponse> mapFromJson(dynamic json) {
    final map = <String, GoalStudyPlanResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = GoalStudyPlanResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of GoalStudyPlanResponse-objects as value to a dart map
  static Map<String, List<GoalStudyPlanResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<GoalStudyPlanResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = GoalStudyPlanResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'goal_name',
    'goal_description',
    'first_objective_name',
    'first_objective_description',
    'milestones',
  };
}

