// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileControllerHash() => r'2f3f1de9cd2110c3d2e0d9ce57b84058482efc10';

/// Provides the signed-in user's profile. Mock-backed while the backend doesn't
/// exist. See docs/backend_contract.md (GET /me).
///
/// Copied from [profileController].
@ProviderFor(profileController)
final profileControllerProvider =
    AutoDisposeFutureProvider<UserProfile>.internal(
  profileController,
  name: r'profileControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProfileControllerRef = AutoDisposeFutureProviderRef<UserProfile>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
