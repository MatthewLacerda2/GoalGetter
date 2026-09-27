// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_start_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appStartController)
final appStartControllerProvider = AppStartControllerProvider._();

final class AppStartControllerProvider
    extends
        $FunctionalProvider<
          AppStartController,
          AppStartController,
          AppStartController
        >
    with $Provider<AppStartController> {
  AppStartControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStartControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStartControllerHash();

  @$internal
  @override
  $ProviderElement<AppStartController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppStartController create(Ref ref) {
    return appStartController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppStartController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppStartController>(value),
    );
  }
}

String _$appStartControllerHash() =>
    r'5b9ee2c4c2b49edece560ce7ed788740fe05b741';

/// Where the splash (`/`) sends the student: [AppStartController]'s answer,
/// asked once per visit to the splash.
///
/// Auto-disposed and kept alive only by the splash screen watching it, so
/// every visit asks again, as the old `AuthGate` did in its `initState`. The
/// router listens to it without keeping it alive and redirects `/` once it
/// has an answer.

@ProviderFor(launchDestination)
final launchDestinationProvider = LaunchDestinationProvider._();

/// Where the splash (`/`) sends the student: [AppStartController]'s answer,
/// asked once per visit to the splash.
///
/// Auto-disposed and kept alive only by the splash screen watching it, so
/// every visit asks again, as the old `AuthGate` did in its `initState`. The
/// router listens to it without keeping it alive and redirects `/` once it
/// has an answer.

final class LaunchDestinationProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppStartDestination>,
          AppStartDestination,
          FutureOr<AppStartDestination>
        >
    with
        $FutureModifier<AppStartDestination>,
        $FutureProvider<AppStartDestination> {
  /// Where the splash (`/`) sends the student: [AppStartController]'s answer,
  /// asked once per visit to the splash.
  ///
  /// Auto-disposed and kept alive only by the splash screen watching it, so
  /// every visit asks again, as the old `AuthGate` did in its `initState`. The
  /// router listens to it without keeping it alive and redirects `/` once it
  /// has an answer.
  LaunchDestinationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launchDestinationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launchDestinationHash();

  @$internal
  @override
  $FutureProviderElement<AppStartDestination> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppStartDestination> create(Ref ref) {
    return launchDestination(ref);
  }
}

String _$launchDestinationHash() => r'ec1cd0ba1cdbe5722872fb43eacac701c2493e73';
