// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tutor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The chat with the tutor on the active goal. [build] loads its newest page,
/// again whenever the active goal changes (#220); `ref.invalidate` loads it
/// again too - the retry after a failed load.
///
/// Every call made after the first page drops its answer once the chat it
/// started on is gone ([_stillCurrent]).

@ProviderFor(TutorController)
final tutorControllerProvider = TutorControllerProvider._();

/// The chat with the tutor on the active goal. [build] loads its newest page,
/// again whenever the active goal changes (#220); `ref.invalidate` loads it
/// again too - the retry after a failed load.
///
/// Every call made after the first page drops its answer once the chat it
/// started on is gone ([_stillCurrent]).
final class TutorControllerProvider
    extends $AsyncNotifierProvider<TutorController, TutorState> {
  /// The chat with the tutor on the active goal. [build] loads its newest page,
  /// again whenever the active goal changes (#220); `ref.invalidate` loads it
  /// again too - the retry after a failed load.
  ///
  /// Every call made after the first page drops its answer once the chat it
  /// started on is gone ([_stillCurrent]).
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

String _$tutorControllerHash() => r'581354f0049c9dfa6365c2cda52ea3ff08bee7af';

/// The chat with the tutor on the active goal. [build] loads its newest page,
/// again whenever the active goal changes (#220); `ref.invalidate` loads it
/// again too - the retry after a failed load.
///
/// Every call made after the first page drops its answer once the chat it
/// started on is gone ([_stillCurrent]).

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
