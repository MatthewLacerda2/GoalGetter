// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_goal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The id of the student's active goal, or null when he has none: the
/// server's `students.current_goal_id`, as the app last heard it (#220).
///
/// The server is the source of truth, and this is its one copy in the app.
/// It is written only by code that has just heard the server's answer — the
/// launch's GET /goals, every GET /goals after it, a set-active, a delete, a
/// goal created — and everything scoped to the active goal (Home, the Tutor,
/// the lesson, the resources) watches it, so a switch refreshes all of them
/// without any of them being told to.
///
/// The device keeps it too (SettingsStorage), so a launch that cannot reach the
/// server still knows where the student was. A new session may be another
/// student, so the stored id is read again when one starts. Not when one ends:
/// every goal-scoped screen is on its way out then, and a change here would
/// have each of them ask the server once more, with no session to ask with.

@ProviderFor(ActiveGoal)
final activeGoalProvider = ActiveGoalProvider._();

/// The id of the student's active goal, or null when he has none: the
/// server's `students.current_goal_id`, as the app last heard it (#220).
///
/// The server is the source of truth, and this is its one copy in the app.
/// It is written only by code that has just heard the server's answer — the
/// launch's GET /goals, every GET /goals after it, a set-active, a delete, a
/// goal created — and everything scoped to the active goal (Home, the Tutor,
/// the lesson, the resources) watches it, so a switch refreshes all of them
/// without any of them being told to.
///
/// The device keeps it too (SettingsStorage), so a launch that cannot reach the
/// server still knows where the student was. A new session may be another
/// student, so the stored id is read again when one starts. Not when one ends:
/// every goal-scoped screen is on its way out then, and a change here would
/// have each of them ask the server once more, with no session to ask with.
final class ActiveGoalProvider extends $NotifierProvider<ActiveGoal, String?> {
  /// The id of the student's active goal, or null when he has none: the
  /// server's `students.current_goal_id`, as the app last heard it (#220).
  ///
  /// The server is the source of truth, and this is its one copy in the app.
  /// It is written only by code that has just heard the server's answer — the
  /// launch's GET /goals, every GET /goals after it, a set-active, a delete, a
  /// goal created — and everything scoped to the active goal (Home, the Tutor,
  /// the lesson, the resources) watches it, so a switch refreshes all of them
  /// without any of them being told to.
  ///
  /// The device keeps it too (SettingsStorage), so a launch that cannot reach the
  /// server still knows where the student was. A new session may be another
  /// student, so the stored id is read again when one starts. Not when one ends:
  /// every goal-scoped screen is on its way out then, and a change here would
  /// have each of them ask the server once more, with no session to ask with.
  ActiveGoalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGoalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGoalHash();

  @$internal
  @override
  ActiveGoal create() => ActiveGoal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeGoalHash() => r'71e9b332fb00d8f34442703cbb96a25180c7519e';

/// The id of the student's active goal, or null when he has none: the
/// server's `students.current_goal_id`, as the app last heard it (#220).
///
/// The server is the source of truth, and this is its one copy in the app.
/// It is written only by code that has just heard the server's answer — the
/// launch's GET /goals, every GET /goals after it, a set-active, a delete, a
/// goal created — and everything scoped to the active goal (Home, the Tutor,
/// the lesson, the resources) watches it, so a switch refreshes all of them
/// without any of them being told to.
///
/// The device keeps it too (SettingsStorage), so a launch that cannot reach the
/// server still knows where the student was. A new session may be another
/// student, so the stored id is read again when one starts. Not when one ends:
/// every goal-scoped screen is on its way out then, and a change here would
/// have each of them ask the server once more, with no session to ask with.

abstract class _$ActiveGoal extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
