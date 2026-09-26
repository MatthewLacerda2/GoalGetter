// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(profileApi)
final profileApiProvider = ProfileApiProvider._();

final class ProfileApiProvider
    extends $FunctionalProvider<ProfileApi, ProfileApi, ProfileApi>
    with $Provider<ProfileApi> {
  ProfileApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileApiHash();

  @$internal
  @override
  $ProviderElement<ProfileApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ProfileApi create(Ref ref) {
    return profileApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileApi>(value),
    );
  }
}

String _$profileApiHash() => r'465ae9ffbf98dea53bd831c277dfe64ac64ff4bd';
