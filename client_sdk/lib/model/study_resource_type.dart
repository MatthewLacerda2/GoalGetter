//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class StudyResourceType {
  /// Instantiate a new enum with the provided [value].
  const StudyResourceType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const pdf = StudyResourceType._(r'pdf');
  static const webpage = StudyResourceType._(r'webpage');
  static const youtube = StudyResourceType._(r'youtube');

  /// List of all possible values in this [enum][StudyResourceType].
  static const values = <StudyResourceType>[
    pdf,
    webpage,
    youtube,
  ];

  static StudyResourceType? fromJson(dynamic value) => StudyResourceTypeTypeTransformer().decode(value);

  static List<StudyResourceType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <StudyResourceType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = StudyResourceType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [StudyResourceType] to String,
/// and [decode] dynamic data back to [StudyResourceType].
class StudyResourceTypeTypeTransformer {
  factory StudyResourceTypeTypeTransformer() => _instance ??= const StudyResourceTypeTypeTransformer._();

  const StudyResourceTypeTypeTransformer._();

  String encode(StudyResourceType data) => data.value;

  /// Decodes a [dynamic value][data] to a StudyResourceType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  StudyResourceType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'pdf': return StudyResourceType.pdf;
        case r'webpage': return StudyResourceType.webpage;
        case r'youtube': return StudyResourceType.youtube;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [StudyResourceTypeTypeTransformer] instance.
  static StudyResourceTypeTypeTransformer? _instance;
}

