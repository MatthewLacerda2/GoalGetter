// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Step 3 of goal creation: confirming [draft] creates the goal, or starting
/// over drops it.
///
/// `POST /goals` needs a session. The draft is held (`PendingGoalDraft`) from
/// the moment he confirms until the goal exists, so a detour to the sign-in
/// screen — none to begin with, or a 401 the client could not refresh — loses
/// nothing he said.

@ProviderFor(StudyPlanController)
final studyPlanControllerProvider = StudyPlanControllerFamily._();

/// Step 3 of goal creation: confirming [draft] creates the goal, or starting
/// over drops it.
///
/// `POST /goals` needs a session. The draft is held (`PendingGoalDraft`) from
/// the moment he confirms until the goal exists, so a detour to the sign-in
/// screen — none to begin with, or a 401 the client could not refresh — loses
/// nothing he said.
final class StudyPlanControllerProvider
    extends $NotifierProvider<StudyPlanController, StudyPlanState> {
  /// Step 3 of goal creation: confirming [draft] creates the goal, or starting
  /// over drops it.
  ///
  /// `POST /goals` needs a session. The draft is held (`PendingGoalDraft`) from
  /// the moment he confirms until the goal exists, so a detour to the sign-in
  /// screen — none to begin with, or a 401 the client could not refresh — loses
  /// nothing he said.
  StudyPlanControllerProvider._({
    required StudyPlanControllerFamily super.from,
    required GoalDraft super.argument,
  }) : super(
         retry: null,
         name: r'studyPlanControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$studyPlanControllerHash();

  @override
  String toString() {
    return r'studyPlanControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StudyPlanController create() => StudyPlanController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StudyPlanState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StudyPlanState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudyPlanControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$studyPlanControllerHash() =>
    r'ab96209b201c0f79497a2892279c6572b9df9902';

/// Step 3 of goal creation: confirming [draft] creates the goal, or starting
/// over drops it.
///
/// `POST /goals` needs a session. The draft is held (`PendingGoalDraft`) from
/// the moment he confirms until the goal exists, so a detour to the sign-in
/// screen — none to begin with, or a 401 the client could not refresh — loses
/// nothing he said.

final class StudyPlanControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          StudyPlanController,
          StudyPlanState,
          StudyPlanState,
          StudyPlanState,
          GoalDraft
        > {
  StudyPlanControllerFamily._()
    : super(
        retry: null,
        name: r'studyPlanControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Step 3 of goal creation: confirming [draft] creates the goal, or starting
  /// over drops it.
  ///
  /// `POST /goals` needs a session. The draft is held (`PendingGoalDraft`) from
  /// the moment he confirms until the goal exists, so a detour to the sign-in
  /// screen — none to begin with, or a 401 the client could not refresh — loses
  /// nothing he said.

  StudyPlanControllerProvider call(GoalDraft draft) =>
      StudyPlanControllerProvider._(argument: draft, from: this);

  @override
  String toString() => r'studyPlanControllerProvider';
}

/// Step 3 of goal creation: confirming [draft] creates the goal, or starting
/// over drops it.
///
/// `POST /goals` needs a session. The draft is held (`PendingGoalDraft`) from
/// the moment he confirms until the goal exists, so a detour to the sign-in
/// screen — none to begin with, or a 401 the client could not refresh — loses
/// nothing he said.

abstract class _$StudyPlanController extends $Notifier<StudyPlanState> {
  late final _$args = ref.$arg as GoalDraft;
  GoalDraft get draft => _$args;

  StudyPlanState build(GoalDraft draft);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<StudyPlanState, StudyPlanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StudyPlanState, StudyPlanState>,
              StudyPlanState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
