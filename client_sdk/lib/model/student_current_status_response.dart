//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class StudentCurrentStatusResponse {
  /// Returns a new [StudentCurrentStatusResponse] instance.
  StudentCurrentStatusResponse({
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.overallXp,
    this.goalId,
    this.goalName,
    required this.currentStreak,
  });

  String studentId;

  String studentName;

  String studentEmail;

  int overallXp;

  String? goalId;

  String? goalName;

  int currentStreak;

  @override
  bool operator ==(Object other) => identical(this, other) || other is StudentCurrentStatusResponse &&
    other.studentId == studentId &&
    other.studentName == studentName &&
    other.studentEmail == studentEmail &&
    other.overallXp == overallXp &&
    other.goalId == goalId &&
    other.goalName == goalName &&
    other.currentStreak == currentStreak;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (studentId.hashCode) +
    (studentName.hashCode) +
    (studentEmail.hashCode) +
    (overallXp.hashCode) +
    (goalId == null ? 0 : goalId!.hashCode) +
    (goalName == null ? 0 : goalName!.hashCode) +
    (currentStreak.hashCode);

  @override
  String toString() => 'StudentCurrentStatusResponse[studentId=$studentId, studentName=$studentName, studentEmail=$studentEmail, overallXp=$overallXp, goalId=$goalId, goalName=$goalName, currentStreak=$currentStreak]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'student_id'] = this.studentId;
      json[r'student_name'] = this.studentName;
      json[r'student_email'] = this.studentEmail;
      json[r'overall_xp'] = this.overallXp;
    if (this.goalId != null) {
      json[r'goal_id'] = this.goalId;
    } else {
      json[r'goal_id'] = null;
    }
    if (this.goalName != null) {
      json[r'goal_name'] = this.goalName;
    } else {
      json[r'goal_name'] = null;
    }
      json[r'current_streak'] = this.currentStreak;
    return json;
  }

  /// Returns a new [StudentCurrentStatusResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static StudentCurrentStatusResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "StudentCurrentStatusResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "StudentCurrentStatusResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return StudentCurrentStatusResponse(
        studentId: mapValueOfType<String>(json, r'student_id')!,
        studentName: mapValueOfType<String>(json, r'student_name')!,
        studentEmail: mapValueOfType<String>(json, r'student_email')!,
        overallXp: mapValueOfType<int>(json, r'overall_xp')!,
        goalId: mapValueOfType<String>(json, r'goal_id'),
        goalName: mapValueOfType<String>(json, r'goal_name'),
        currentStreak: mapValueOfType<int>(json, r'current_streak')!,
      );
    }
    return null;
  }

  static List<StudentCurrentStatusResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StudentCurrentStatusResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StudentCurrentStatusResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, StudentCurrentStatusResponse> mapFromJson(dynamic json) {
    final map = <String, StudentCurrentStatusResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = StudentCurrentStatusResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of StudentCurrentStatusResponse-objects as value to a dart map
  static Map<String, List<StudentCurrentStatusResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<StudentCurrentStatusResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = StudentCurrentStatusResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'student_id',
    'student_name',
    'student_email',
    'overall_xp',
    'current_streak',
  };
}

