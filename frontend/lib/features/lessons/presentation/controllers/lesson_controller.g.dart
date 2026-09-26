// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then a
/// review round of the wrong ones that is never submitted.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once - see [_resumeAt] and `_hasSubmittedAnswers`.

@ProviderFor(LessonController)
final lessonControllerProvider = LessonControllerProvider._();

/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then a
/// review round of the wrong ones that is never submitted.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once - see [_resumeAt] and `_hasSubmittedAnswers`.
final class LessonControllerProvider
    extends $NotifierProvider<LessonController, LessonState> {
  /// Runs one lesson on the active goal: open it, answer each question once
  /// (graded inline for feedback), submit those answers as one batch, then a
  /// review round of the wrong ones that is never submitted.
  ///
  /// The batch is what the backend marks as a lesson, so it is sent whole and in
  /// order, once - see [_resumeAt] and `_hasSubmittedAnswers`.
  LessonControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lessonControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lessonControllerHash();

  @$internal
  @override
  LessonController create() => LessonController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LessonState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LessonState>(value),
    );
  }
}

String _$lessonControllerHash() => r'36c9c384fcb1eb2a8b84529075385c0e40f6d715';

/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then a
/// review round of the wrong ones that is never submitted.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once - see [_resumeAt] and `_hasSubmittedAnswers`.

abstract class _$LessonController extends $Notifier<LessonState> {
  LessonState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LessonState, LessonState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LessonState, LessonState>,
              LessonState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
