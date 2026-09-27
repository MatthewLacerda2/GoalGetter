import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/features/home/data/home_api.dart';
import 'package:goal_getter/features/home/domain/home_dashboard.dart';

part 'home_controller.g.dart';

/// The Home dashboard for the active goal; null when there is none. A finished
/// lesson invalidates it (LessonController), so Home shows the new rating.
///
/// The backend scopes GET /home to the active goal on its own; watching
/// [activeGoalProvider] is what loads it again when the student switches
/// goals, since Home stays mounted under the goals list.
@riverpod
Future<HomeDashboard?> homeController(Ref ref) {
  ref.watch(activeGoalProvider);
  return ref.watch(homeApiProvider).fetch();
}
