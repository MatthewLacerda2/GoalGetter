//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CreateMessageRequest {
  /// Returns a new [CreateMessageRequest] instance.
  CreateMessageRequest({
    this.messagesList = const [],
  });

  List<CreateMessageRequestItem> messagesList;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CreateMessageRequest &&
    _deepEquality.equals(other.messagesList, messagesList);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (messagesList.hashCode);

  @override
  String toString() => 'CreateMessageRequest[messagesList=$messagesList]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'messages_list'] = this.messagesList;
    return json;
  }

  /// Returns a new [CreateMessageRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CreateMessageRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CreateMessageRequest[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CreateMessageRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CreateMessageRequest(
        messagesList: CreateMessageRequestItem.listFromJson(json[r'messages_list']),
      );
    }
    return null;
  }

  static List<CreateMessageRequest> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CreateMessageRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CreateMessageRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CreateMessageRequest> mapFromJson(dynamic json) {
    final map = <String, CreateMessageRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CreateMessageRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CreateMessageRequest-objects as value to a dart map
  static Map<String, List<CreateMessageRequest>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CreateMessageRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CreateMessageRequest.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'messages_list',
  };
}

