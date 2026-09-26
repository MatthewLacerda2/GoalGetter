// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The student's goals (`GET /goals`). The list and the detail screen both read
/// it: there is no per-goal GET. Refresh with `ref.invalidate`.

@ProviderFor(goalsListController)
final goalsListControllerProvider = GoalsListControllerProvider._();

/// The student's goals (`GET /goals`). The list and the detail screen both read
/// it: there is no per-goal GET. Refresh with `ref.invalidate`.

final class GoalsListControllerProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Goal>>,
          List<Goal>,
          FutureOr<List<Goal>>
        >
    with $FutureModifier<List<Goal>>, $FutureProvider<List<Goal>> {
  /// The student's goals (`GET /goals`). The list and the detail screen both read
  /// it: there is no per-goal GET. Refresh with `ref.invalidate`.
  GoalsListControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalsListControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalsListControllerHash();

  @$internal
  @override
  $FutureProviderElement<List<Goal>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Goal>> create(Ref ref) {
    return goalsListController(ref);
  }
}

String _$goalsListControllerHash() =>
    r'21c2993954595c3668f5c61a27f00185f374e534';
