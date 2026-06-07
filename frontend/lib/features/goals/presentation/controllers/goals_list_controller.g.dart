// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$goalsListControllerHash() =>
    r'588453c602190e47eecf0450bd30cf0a0d668b3a';

/// Provides the user's goals. Mock-backed while the backend doesn't exist;
/// refresh via `ref.invalidate`. See docs/backend_contract.md (GET /goals).
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
