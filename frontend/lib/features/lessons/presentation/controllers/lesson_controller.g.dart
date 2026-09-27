// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then
/// review rounds of the wrong ones - never submitted - until every one of them
/// has been answered right.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once: only a [FirstRound] is ever submitted, and a gap in it is
/// returned to rather than sent.
///
/// Every decision about the lesson's flow is taken here; the screen draws the
/// [LessonState] it is handed. Time is read from `package:clock`, so a test
/// decides how long a question was on screen.
///
/// Opening is [build]: the screen watching the provider opens a lesson, and
/// `ref.invalidate` opens a new one - the retry after a failed start.

@ProviderFor(LessonController)
final lessonControllerProvider = LessonControllerProvider._();

/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then
/// review rounds of the wrong ones - never submitted - until every one of them
/// has been answered right.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once: only a [FirstRound] is ever submitted, and a gap in it is
/// returned to rather than sent.
///
/// Every decision about the lesson's flow is taken here; the screen draws the
/// [LessonState] it is handed. Time is read from `package:clock`, so a test
/// decides how long a question was on screen.
///
/// Opening is [build]: the screen watching the provider opens a lesson, and
/// `ref.invalidate` opens a new one - the retry after a failed start.
final class LessonControllerProvider
    extends $AsyncNotifierProvider<LessonController, LessonState> {
  /// Runs one lesson on the active goal: open it, answer each question once
  /// (graded inline for feedback), submit those answers as one batch, then
  /// review rounds of the wrong ones - never submitted - until every one of them
  /// has been answered right.
  ///
  /// The batch is what the backend marks as a lesson, so it is sent whole and in
  /// order, once: only a [FirstRound] is ever submitted, and a gap in it is
  /// returned to rather than sent.
  ///
  /// Every decision about the lesson's flow is taken here; the screen draws the
  /// [LessonState] it is handed. Time is read from `package:clock`, so a test
  /// decides how long a question was on screen.
  ///
  /// Opening is [build]: the screen watching the provider opens a lesson, and
  /// `ref.invalidate` opens a new one - the retry after a failed start.
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
}

String _$lessonControllerHash() => r'67217fadedadc6c0f187e4d18fcca2122feebfa9';

/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then
/// review rounds of the wrong ones - never submitted - until every one of them
/// has been answered right.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once: only a [FirstRound] is ever submitted, and a gap in it is
/// returned to rather than sent.
///
/// Every decision about the lesson's flow is taken here; the screen draws the
/// [LessonState] it is handed. Time is read from `package:clock`, so a test
/// decides how long a question was on screen.
///
/// Opening is [build]: the screen watching the provider opens a lesson, and
/// `ref.invalidate` opens a new one - the retry after a failed start.

abstract class _$LessonController extends $AsyncNotifier<LessonState> {
  FutureOr<LessonState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LessonState>, LessonState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LessonState>, LessonState>,
              AsyncValue<LessonState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
