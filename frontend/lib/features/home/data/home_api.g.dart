// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeApi)
final homeApiProvider = HomeApiProvider._();

final class HomeApiProvider
    extends $FunctionalProvider<HomeApi, HomeApi, HomeApi>
    with $Provider<HomeApi> {
  HomeApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeApiHash();

  @$internal
  @override
  $ProviderElement<HomeApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HomeApi create(Ref ref) {
    return homeApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeApi>(value),
    );
  }
}

String _$homeApiHash() => r'6be1f36da1476e150ab75b933b6d3595803e3178';
