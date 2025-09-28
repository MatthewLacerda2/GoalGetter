//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ResourceItem {
  /// Returns a new [ResourceItem] instance.
  ResourceItem({
    required this.id,
    required this.resourceType,
    required this.name,
    required this.description,
    required this.link,
    this.imageUrl,
  });

  String id;

  StudyResourceType resourceType;

  String name;

  String description;

  String link;

  String? imageUrl;

  @override
  bool operator ==(Object other) => identical(this, other) || other is ResourceItem &&
    other.id == id &&
    other.resourceType == resourceType &&
    other.name == name &&
    other.description == description &&
    other.link == link &&
    other.imageUrl == imageUrl;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (id.hashCode) +
    (resourceType.hashCode) +
    (name.hashCode) +
    (description.hashCode) +
    (link.hashCode) +
    (imageUrl == null ? 0 : imageUrl!.hashCode);

  @override
  String toString() => 'ResourceItem[id=$id, resourceType=$resourceType, name=$name, description=$description, link=$link, imageUrl=$imageUrl]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'id'] = this.id;
      json[r'resource_type'] = this.resourceType;
      json[r'name'] = this.name;
      json[r'description'] = this.description;
      json[r'link'] = this.link;
    if (this.imageUrl != null) {
      json[r'image_url'] = this.imageUrl;
    } else {
      json[r'image_url'] = null;
    }
    return json;
  }

  /// Returns a new [ResourceItem] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ResourceItem? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "ResourceItem[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "ResourceItem[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ResourceItem(
        id: mapValueOfType<String>(json, r'id')!,
        resourceType: StudyResourceType.fromJson(json[r'resource_type'])!,
        name: mapValueOfType<String>(json, r'name')!,
        description: mapValueOfType<String>(json, r'description')!,
        link: mapValueOfType<String>(json, r'link')!,
        imageUrl: mapValueOfType<String>(json, r'image_url'),
      );
    }
    return null;
  }

  static List<ResourceItem> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <ResourceItem>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ResourceItem.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ResourceItem> mapFromJson(dynamic json) {
    final map = <String, ResourceItem>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ResourceItem.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ResourceItem-objects as value to a dart map
  static Map<String, List<ResourceItem>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<ResourceItem>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ResourceItem.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'resource_type',
    'name',
    'description',
    'link',
  };
}

