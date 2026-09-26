// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lessons_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lessonsApi)
final lessonsApiProvider = LessonsApiProvider._();

final class LessonsApiProvider
    extends $FunctionalProvider<LessonsApi, LessonsApi, LessonsApi>
    with $Provider<LessonsApi> {
  LessonsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lessonsApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lessonsApiHash();

  @$internal
  @override
  $ProviderElement<LessonsApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LessonsApi create(Ref ref) {
    return lessonsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LessonsApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LessonsApi>(value),
    );
  }
}

String _$lessonsApiHash() => r'fea666ea8a0125cecd3cbcacd694b1704db7307d';
