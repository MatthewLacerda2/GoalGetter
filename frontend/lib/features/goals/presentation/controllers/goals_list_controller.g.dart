// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The student's goals (`GET /goals`). The list and the detail screen both read
/// it: there is no per-goal GET. Refresh with `ref.invalidate`.
///
/// Each answer also says which goal the server holds active, and the app's
/// copy ([ActiveGoal]) follows it: a goal switched on another device reaches
/// Home and the Tutor the next time this list loads.

@ProviderFor(goalsListController)
final goalsListControllerProvider = GoalsListControllerProvider._();

/// The student's goals (`GET /goals`). The list and the detail screen both read
/// it: there is no per-goal GET. Refresh with `ref.invalidate`.
///
/// Each answer also says which goal the server holds active, and the app's
/// copy ([ActiveGoal]) follows it: a goal switched on another device reaches
/// Home and the Tutor the next time this list loads.

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
  ///
  /// Each answer also says which goal the server holds active, and the app's
  /// copy ([ActiveGoal]) follows it: a goal switched on another device reaches
  /// Home and the Tutor the next time this list loads.
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
    r'0bb66e55a90cce0c3723d33cc908e32a9436219e';
