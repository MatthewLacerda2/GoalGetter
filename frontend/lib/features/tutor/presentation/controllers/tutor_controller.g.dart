// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TutorController)
final tutorControllerProvider = TutorControllerProvider._();

final class TutorControllerProvider
    extends $NotifierProvider<TutorController, TutorState> {
  TutorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tutorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tutorControllerHash();

  @$internal
  @override
  TutorController create() => TutorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TutorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TutorState>(value),
    );
  }
}

String _$tutorControllerHash() => r'095160fdb76ae95e1bfd29a4b35285e7c7de8745';

abstract class _$TutorController extends $Notifier<TutorState> {
  TutorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TutorState, TutorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TutorState, TutorState>,
              TutorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
