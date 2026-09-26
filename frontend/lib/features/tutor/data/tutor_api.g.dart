// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutor_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tutorApi)
final tutorApiProvider = TutorApiProvider._();

final class TutorApiProvider
    extends $FunctionalProvider<TutorApi, TutorApi, TutorApi>
    with $Provider<TutorApi> {
  TutorApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorApiHash();

  @$internal
  @override
  $ProviderElement<TutorApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TutorApi create(Ref ref) {
    return tutorApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TutorApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TutorApi>(value),
    );
  }
}

String _$tutorApiHash() => r'f314faa303fba875447f8e10b8ef6b58f32ae9b7';
