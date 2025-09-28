//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResourceResponse {
  /// Returns a new [ResourceResponse] instance.
  ResourceResponse({
    this.resources = const [],
  });

  List<ResourceItem> resources;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResourceResponse &&
    _deepEquality.equals(other.resources, resources);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (resources.hashCode);

  @override
  String toString() => 'ResourceResponse[resources=$resources]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'resources'] = this.resources;
    return json;
  }

  /// Returns a new [ResourceResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResourceResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ResourceResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ResourceResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ResourceResponse(
        resources: ResourceItem.listFromJson(json[r'resources']),
      );
    }
    return null;
  }

  static List<ResourceResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResourceResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResourceResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResourceResponse> mapFromJson(dynamic json) {
    final map = <String, ResourceResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResourceResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResourceResponse-objects as value to a dart map
  static Map<String, List<ResourceResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResourceResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResourceResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'resources',
  };
}

