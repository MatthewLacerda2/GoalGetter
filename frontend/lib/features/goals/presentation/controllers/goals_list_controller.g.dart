// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$goalsListControllerHash() =>
    r'e897d8c6177890b3a701f09778e89e35cdf0febc';

/// The student's goals (`GET /goals`). The list and the detail screen both read
/// it: there is no per-goal GET. Refresh with `ref.invalidate`.
///
/// Copied from [goalsListController].
@ProviderFor(goalsListController)
final goalsListControllerProvider =
    AutoDisposeFutureProvider<List<Goal>>.internal(
  goalsListController,
  name: r'goalsListControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$goalsListControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GoalsListControllerRef = AutoDisposeFutureProviderRef<List<Goal>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
