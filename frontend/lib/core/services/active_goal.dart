import 'package:goal_getter/core/services/session.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_goal.g.dart';

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
@Riverpod(keepAlive: true)
class ActiveGoal extends _$ActiveGoal {
  @override
  String? build() {
    ref.listen(signedInProvider, (_, signedIn) {
      if (signedIn) state = _stored();
    });
    return _stored();
  }

  String? _stored() {
    final stored = ref.read(settingsStorageProvider).readCurrentGoalId();
    return stored == null || stored.isEmpty ? null : stored;
  }

  /// The server said [goalId] is the active goal; null, that there is none.
  Future<void> set(String? goalId) async {
    await ref.read(settingsStorageProvider).storeCurrentGoalId(goalId);
    state = goalId;
  }

  /// The server deleted [goalId]. When it was the active goal the server
  /// cleared `current_goal_id`, so there is none now.
  Future<void> deleted(String goalId) async {
    if (state == goalId) await set(null);
  }
}
