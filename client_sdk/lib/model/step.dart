//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Step {
  /// Returns a new [Step] instance.
  Step({
    required this.title,
    required this.description,
  });

  /// A title for the step
  String title;

  /// A description of the step
  String description;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Step &&
    other.title == title &&
    other.description == description;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title.hashCode) +
    (description.hashCode);

  @override
  String toString() => 'Step[title=$title, description=$description]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'title'] = this.title;
      json[r'description'] = this.description;
    return json;
  }

  /// Returns a new [Step] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Step? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Step[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Step[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Step(
        title: mapValueOfType<String>(json, r'title')!,
        description: mapValueOfType<String>(json, r'description')!,
      );
    }
    return null;
  }

  static List<Step> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Step>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Step.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Step> mapFromJson(dynamic json) {
    final map = <String, Step>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Step.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Step-objects as value to a dart map
  static Map<String, List<Step>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Step>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Step.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'description',
  };
}

