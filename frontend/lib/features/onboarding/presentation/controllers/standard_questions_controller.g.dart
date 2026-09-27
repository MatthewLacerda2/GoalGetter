// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standard_questions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The last step of goal creation: [questions] of goal [goalId],
/// answered while its first lesson generates.
///
/// [questions] are the ones the screen can draw — it leaves out a key this
/// build has no sentence for — so every index here is one on screen.
///
/// **Nothing here blocks.** The answers are sent without waiting and a failure
/// is swallowed on purpose: they are worth having and worth nothing at all
/// compared with the lesson he is on his way to, and there is no screen on
/// which to show him an error about a question he has finished with.

@ProviderFor(StandardQuestionsController)
final standardQuestionsControllerProvider =
    StandardQuestionsControllerFamily._();

/// The last step of goal creation: [questions] of goal [goalId],
/// answered while its first lesson generates.
///
/// [questions] are the ones the screen can draw — it leaves out a key this
/// build has no sentence for — so every index here is one on screen.
///
/// **Nothing here blocks.** The answers are sent without waiting and a failure
/// is swallowed on purpose: they are worth having and worth nothing at all
/// compared with the lesson he is on his way to, and there is no screen on
/// which to show him an error about a question he has finished with.
final class StandardQuestionsControllerProvider
    extends
        $NotifierProvider<StandardQuestionsController, StandardQuestionsState> {
  /// The last step of goal creation: [questions] of goal [goalId],
  /// answered while its first lesson generates.
  ///
  /// [questions] are the ones the screen can draw — it leaves out a key this
  /// build has no sentence for — so every index here is one on screen.
  ///
  /// **Nothing here blocks.** The answers are sent without waiting and a failure
  /// is swallowed on purpose: they are worth having and worth nothing at all
  /// compared with the lesson he is on his way to, and there is no screen on
  /// which to show him an error about a question he has finished with.
  StandardQuestionsControllerProvider._({
    required StandardQuestionsControllerFamily super.from,
    required (String, List<StandardQuestion>) super.argument,
  }) : super(
         retry: null,
         name: r'standardQuestionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$standardQuestionsControllerHash();

  @override
  String toString() {
    return r'standardQuestionsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  StandardQuestionsController create() => StandardQuestionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StandardQuestionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StandardQuestionsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StandardQuestionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$standardQuestionsControllerHash() =>
    r'5149987bd30089427ac8ea0b02c28197123988bc';

/// The last step of goal creation: [questions] of goal [goalId],
/// answered while its first lesson generates.
///
/// [questions] are the ones the screen can draw — it leaves out a key this
/// build has no sentence for — so every index here is one on screen.
///
/// **Nothing here blocks.** The answers are sent without waiting and a failure
/// is swallowed on purpose: they are worth having and worth nothing at all
/// compared with the lesson he is on his way to, and there is no screen on
/// which to show him an error about a question he has finished with.

final class StandardQuestionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          StandardQuestionsController,
          StandardQuestionsState,
          StandardQuestionsState,
          StandardQuestionsState,
          (String, List<StandardQuestion>)
        > {
  StandardQuestionsControllerFamily._()
    : super(
        retry: null,
        name: r'standardQuestionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The last step of goal creation: [questions] of goal [goalId],
  /// answered while its first lesson generates.
  ///
  /// [questions] are the ones the screen can draw — it leaves out a key this
  /// build has no sentence for — so every index here is one on screen.
  ///
  /// **Nothing here blocks.** The answers are sent without waiting and a failure
  /// is swallowed on purpose: they are worth having and worth nothing at all
  /// compared with the lesson he is on his way to, and there is no screen on
  /// which to show him an error about a question he has finished with.

  StandardQuestionsControllerProvider call(
    String goalId,
    List<StandardQuestion> questions,
  ) => StandardQuestionsControllerProvider._(
    argument: (goalId, questions),
    from: this,
  );

  @override
  String toString() => r'standardQuestionsControllerProvider';
}

/// The last step of goal creation: [questions] of goal [goalId],
/// answered while its first lesson generates.
///
/// [questions] are the ones the screen can draw — it leaves out a key this
/// build has no sentence for — so every index here is one on screen.
///
/// **Nothing here blocks.** The answers are sent without waiting and a failure
/// is swallowed on purpose: they are worth having and worth nothing at all
/// compared with the lesson he is on his way to, and there is no screen on
/// which to show him an error about a question he has finished with.

abstract class _$StandardQuestionsController
    extends $Notifier<StandardQuestionsState> {
  late final _$args = ref.$arg as (String, List<StandardQuestion>);
  String get goalId => _$args.$1;
  List<StandardQuestion> get questions => _$args.$2;

  StandardQuestionsState build(String goalId, List<StandardQuestion> questions);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<StandardQuestionsState, StandardQuestionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StandardQuestionsState, StandardQuestionsState>,
              StandardQuestionsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
