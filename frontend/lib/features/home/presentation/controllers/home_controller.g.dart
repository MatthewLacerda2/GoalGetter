// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Home dashboard for the active goal; null when there is none. A finished
/// lesson invalidates it (LessonController), so Home shows the new rating.

@ProviderFor(homeController)
final homeControllerProvider = HomeControllerProvider._();

/// The Home dashboard for the active goal; null when there is none. A finished
/// lesson invalidates it (LessonController), so Home shows the new rating.

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

String _$homeControllerHash() => r'b9ee960c12a24ca3b06c8b5b179f08e0a8eaedc8';
