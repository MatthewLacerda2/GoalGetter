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
    r'da33fc2222c3352f9a8b5f96515ad85813209498';
