// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Home dashboard for the active goal; null when there is none. A finished
/// lesson invalidates it (LessonController), so Home shows the new rating.
///
/// The backend scopes GET /home to the active goal on its own; watching
/// [activeGoalProvider] is what loads it again when the student switches
/// goals, since Home stays mounted under the goals list.

@ProviderFor(homeController)
final homeControllerProvider = HomeControllerProvider._();

/// The Home dashboard for the active goal; null when there is none. A finished
/// lesson invalidates it (LessonController), so Home shows the new rating.
///
/// The backend scopes GET /home to the active goal on its own; watching
/// [activeGoalProvider] is what loads it again when the student switches
/// goals, since Home stays mounted under the goals list.

final class HomeControllerProvider
    extends
        $FunctionalProvider<
          AsyncValue<HomeDashboard?>,
          HomeDashboard?,
          FutureOr<HomeDashboard?>
        >
    with $FutureModifier<HomeDashboard?>, $FutureProvider<HomeDashboard?> {
  /// The Home dashboard for the active goal; null when there is none. A finished
  /// lesson invalidates it (LessonController), so Home shows the new rating.
  ///
  /// The backend scopes GET /home to the active goal on its own; watching
  /// [activeGoalProvider] is what loads it again when the student switches
  /// goals, since Home stays mounted under the goals list.
  HomeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeControllerHash();

  @$internal
  @override
  $FutureProviderElement<HomeDashboard?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HomeDashboard?> create(Ref ref) {
    return homeController(ref);
  }
}

String _$homeControllerHash() => r'd89b78eadfaab1059cb51a4300793c20440b1b62';
