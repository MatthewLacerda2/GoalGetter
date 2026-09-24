// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileControllerHash() => r'81c1170f1d038c65f42ad0640f4ecbda58e84ffc';

/// The signed-in user's profile header (GET /me). A finished lesson
/// invalidates it (LessonController): the streak may have moved.
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
