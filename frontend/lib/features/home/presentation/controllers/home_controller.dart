import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/features/home/data/home_api.dart';
import 'package:goal_getter/features/home/domain/home_dashboard.dart';

part 'home_controller.g.dart';

/// The Home dashboard for the active goal; null when there is none. A finished
/// lesson invalidates it (LessonController), so Home shows the new rating.
@riverpod
Future<HomeDashboard?> homeController(Ref ref) {
  return ref.watch(homeApiProvider).fetch();
}
