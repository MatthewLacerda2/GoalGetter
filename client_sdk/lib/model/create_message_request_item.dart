//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateMessageRequestItem {
  /// Returns a new [CreateMessageRequestItem] instance.
  CreateMessageRequestItem({
    required this.message,
    required this.datetime,
  });

  String message;

  DateTime datetime;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateMessageRequestItem &&
    other.message == message &&
    other.datetime == datetime;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (message.hashCode) +
    (datetime.hashCode);

  @override
  String toString() => 'CreateMessageRequestItem[message=$message, datetime=$datetime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'message'] = this.message;
      json[r'datetime'] = this.datetime.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [CreateMessageRequestItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateMessageRequestItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateMessageRequestItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateMessageRequestItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateMessageRequestItem(
        message: mapValueOfType<String>(json, r'message')!,
        datetime: mapDateTime(json, r'datetime', r'')!,
      );
    }
    return null;
  }

  static List<CreateMessageRequestItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateMessageRequestItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateMessageRequestItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateMessageRequestItem> mapFromJson(dynamic json) {
    final map = <String, CreateMessageRequestItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateMessageRequestItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateMessageRequestItem-objects as value to a dart map
  static Map<String, List<CreateMessageRequestItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateMessageRequestItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateMessageRequestItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'message',
    'datetime',
  };
}

