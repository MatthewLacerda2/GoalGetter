import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/features/profile/data/profile_api.dart';
import 'package:goal_getter/features/profile/domain/user_profile.dart';

part 'profile_controller.g.dart';

/// The signed-in user's profile header (GET /me). A finished lesson
/// invalidates it (LessonController): the streak may have moved.
@riverpod
Future<UserProfile> profileController(ProfileControllerRef ref) {
  return ref.watch(profileApiProvider).me();
}
