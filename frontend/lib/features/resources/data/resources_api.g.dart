// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resources_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resourcesApi)
final resourcesApiProvider = ResourcesApiProvider._();

final class ResourcesApiProvider
    extends $FunctionalProvider<ResourcesApi, ResourcesApi, ResourcesApi>
    with $Provider<ResourcesApi> {
  ResourcesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resourcesApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resourcesApiHash();

  @$internal
  @override
  $ProviderElement<ResourcesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ResourcesApi create(Ref ref) {
    return resourcesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResourcesApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResourcesApi>(value),
    );
  }
}

String _$resourcesApiHash() => r'0d805f32f412b7549e9c9b36814eb71fd7f88bae';
