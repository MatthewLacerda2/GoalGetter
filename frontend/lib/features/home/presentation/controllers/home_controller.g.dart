// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeControllerHash() => r'6b80a13d924e300fc8d79069b7ecd839e388249f';

/// The Home dashboard for the active goal; null when there is none. A finished
/// lesson invalidates it (LessonController), so Home shows the new rating.
///
/// Copied from [homeController].
@ProviderFor(homeController)
final homeControllerProvider =
    AutoDisposeFutureProvider<HomeDashboard?>.internal(
  homeController,
  name: r'homeControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef HomeControllerRef = AutoDisposeFutureProviderRef<HomeDashboard?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
