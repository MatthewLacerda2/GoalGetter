// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_goal_draft.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingGoalDraftHash() => r'0c71cdf01847fadc567fc7856625b058e4fbd6f3';

/// The draft being committed, held from the moment the student confirms the
/// study plan until `POST /goals` succeeds. Creating a goal needs a session:
/// when there is none (or it expires mid-call and the API client routes to the
/// start screen), the sign-in brings the student back to this draft instead of
/// making them answer everything again. In memory only: a reload loses it.
///
/// Copied from [PendingGoalDraft].
@ProviderFor(PendingGoalDraft)
final pendingGoalDraftProvider =
    NotifierProvider<PendingGoalDraft, GoalDraft?>.internal(
      PendingGoalDraft.new,
      name: r'pendingGoalDraftProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingGoalDraftHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PendingGoalDraft = Notifier<GoalDraft?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
