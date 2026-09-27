// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_questions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The objective questions Gemini wrote for [prompt], one at a time. The
/// screen owns how a question arrives (the slide, the pause that shows the
/// pick); this owns what was answered and how long each question took
/// (#174), and sends them all to `POST /goals/study-plan`.

@ProviderFor(GoalQuestionsController)
final goalQuestionsControllerProvider = GoalQuestionsControllerFamily._();

/// The objective questions Gemini wrote for [prompt], one at a time. The
/// screen owns how a question arrives (the slide, the pause that shows the
/// pick); this owns what was answered and how long each question took
/// (#174), and sends them all to `POST /goals/study-plan`.
final class GoalQuestionsControllerProvider
    extends $NotifierProvider<GoalQuestionsController, GoalQuestionsState> {
  /// The objective questions Gemini wrote for [prompt], one at a time. The
  /// screen owns how a question arrives (the slide, the pause that shows the
  /// pick); this owns what was answered and how long each question took
  /// (#174), and sends them all to `POST /goals/study-plan`.
  GoalQuestionsControllerProvider._({
    required GoalQuestionsControllerFamily super.from,
    required (String, List<ObjectiveQuestion>) super.argument,
  }) : super(
         retry: null,
         name: r'goalQuestionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalQuestionsControllerHash();

  @override
  String toString() {
    return r'goalQuestionsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GoalQuestionsController create() => GoalQuestionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalQuestionsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalQuestionsState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoalQuestionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalQuestionsControllerHash() =>
    r'9edeff76635f6be94d9bce070571088b42b16aee';

/// The objective questions Gemini wrote for [prompt], one at a time. The
/// screen owns how a question arrives (the slide, the pause that shows the
/// pick); this owns what was answered and how long each question took
/// (#174), and sends them all to `POST /goals/study-plan`.

final class GoalQuestionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          GoalQuestionsController,
          GoalQuestionsState,
          GoalQuestionsState,
          GoalQuestionsState,
          (String, List<ObjectiveQuestion>)
        > {
  GoalQuestionsControllerFamily._()
    : super(
        retry: null,
        name: r'goalQuestionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The objective questions Gemini wrote for [prompt], one at a time. The
  /// screen owns how a question arrives (the slide, the pause that shows the
  /// pick); this owns what was answered and how long each question took
  /// (#174), and sends them all to `POST /goals/study-plan`.

  GoalQuestionsControllerProvider call(
    String prompt,
    List<ObjectiveQuestion> questions,
  ) => GoalQuestionsControllerProvider._(
    argument: (prompt, questions),
    from: this,
  );

  @override
  String toString() => r'goalQuestionsControllerProvider';
}

/// The objective questions Gemini wrote for [prompt], one at a time. The
/// screen owns how a question arrives (the slide, the pause that shows the
/// pick); this owns what was answered and how long each question took
/// (#174), and sends them all to `POST /goals/study-plan`.

abstract class _$GoalQuestionsController extends $Notifier<GoalQuestionsState> {
  late final _$args = ref.$arg as (String, List<ObjectiveQuestion>);
  String get prompt => _$args.$1;
  List<ObjectiveQuestion> get questions => _$args.$2;

  GoalQuestionsState build(String prompt, List<ObjectiveQuestion> questions);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoalQuestionsState, GoalQuestionsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalQuestionsState, GoalQuestionsState>,
              GoalQuestionsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
