// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The chat with the tutor on the active goal. [build] loads its newest page;
/// `ref.invalidate` loads it again - the retry after a failed load.
///
/// Every call made after the first page holds on to the ref of the build it
/// started in, and drops its answer when that ref is no longer mounted: the
/// provider was disposed, or rebuilt into another chat.

@ProviderFor(TutorController)
final tutorControllerProvider = TutorControllerProvider._();

/// The chat with the tutor on the active goal. [build] loads its newest page;
/// `ref.invalidate` loads it again - the retry after a failed load.
///
/// Every call made after the first page holds on to the ref of the build it
/// started in, and drops its answer when that ref is no longer mounted: the
/// provider was disposed, or rebuilt into another chat.
final class TutorControllerProvider
    extends $AsyncNotifierProvider<TutorController, TutorState> {
  /// The chat with the tutor on the active goal. [build] loads its newest page;
  /// `ref.invalidate` loads it again - the retry after a failed load.
  ///
  /// Every call made after the first page holds on to the ref of the build it
  /// started in, and drops its answer when that ref is no longer mounted: the
  /// provider was disposed, or rebuilt into another chat.
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
}

String _$tutorControllerHash() => r'6262f5aeac7a32db54bcd211c0616197e79fa556';

/// The chat with the tutor on the active goal. [build] loads its newest page;
/// `ref.invalidate` loads it again - the retry after a failed load.
///
/// Every call made after the first page holds on to the ref of the build it
/// started in, and drops its answer when that ref is no longer mounted: the
/// provider was disposed, or rebuilt into another chat.

abstract class _$TutorController extends $AsyncNotifier<TutorState> {
  FutureOr<TutorState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TutorState>, TutorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TutorState>, TutorState>,
              AsyncValue<TutorState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
