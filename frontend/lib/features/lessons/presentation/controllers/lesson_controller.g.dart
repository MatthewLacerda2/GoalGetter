// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lessonControllerHash() => r'e0272f84fd72618b1d1b61e8ff36dbcb9394d598';

/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those first attempts, then a review
/// round of the wrong ones that is never submitted.
///
/// Copied from [LessonController].
@ProviderFor(LessonController)
final lessonControllerProvider =
    AutoDisposeNotifierProvider<LessonController, LessonState>.internal(
  LessonController.new,
  name: r'lessonControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LessonController = AutoDisposeNotifier<LessonState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
