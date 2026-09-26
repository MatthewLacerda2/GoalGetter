// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_goal_draft.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The draft being committed, held from the moment the student confirms the
/// study plan until `POST /goals` succeeds. Creating a goal needs a session:
/// when there is none (or it expires mid-call and the API client routes to the
/// start screen), the sign-in brings the student back to this draft instead of
/// making them answer everything again. In memory only: a reload loses it.

@ProviderFor(PendingGoalDraft)
final pendingGoalDraftProvider = PendingGoalDraftProvider._();

/// The draft being committed, held from the moment the student confirms the
/// study plan until `POST /goals` succeeds. Creating a goal needs a session:
/// when there is none (or it expires mid-call and the API client routes to the
/// start screen), the sign-in brings the student back to this draft instead of
/// making them answer everything again. In memory only: a reload loses it.
final class PendingGoalDraftProvider
    extends $NotifierProvider<PendingGoalDraft, GoalDraft?> {
  /// The draft being committed, held from the moment the student confirms the
  /// study plan until `POST /goals` succeeds. Creating a goal needs a session:
  /// when there is none (or it expires mid-call and the API client routes to the
  /// start screen), the sign-in brings the student back to this draft instead of
  /// making them answer everything again. In memory only: a reload loses it.
  PendingGoalDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingGoalDraftProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingGoalDraftHash();

  @$internal
  @override
  PendingGoalDraft create() => PendingGoalDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalDraft? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalDraft?>(value),
    );
  }
}

String _$pendingGoalDraftHash() => r'0c71cdf01847fadc567fc7856625b058e4fbd6f3';

/// The draft being committed, held from the moment the student confirms the
/// study plan until `POST /goals` succeeds. Creating a goal needs a session:
/// when there is none (or it expires mid-call and the API client routes to the
/// start screen), the sign-in brings the student back to this draft instead of
/// making them answer everything again. In memory only: a reload loses it.

abstract class _$PendingGoalDraft extends $Notifier<GoalDraft?> {
  GoalDraft? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GoalDraft?, GoalDraft?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoalDraft?, GoalDraft?>,
              GoalDraft?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
