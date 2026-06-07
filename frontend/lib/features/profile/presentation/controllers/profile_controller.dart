import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/features/profile/domain/user_profile.dart';
import 'package:goal_getter/features/profile/debug/mock_profile.dart';

part 'profile_controller.g.dart';

/// Provides the signed-in user's profile. Mock-backed while the backend doesn't
/// exist. See docs/backend_contract.md (GET /me).
@riverpod
Future<UserProfile> profileController(ProfileControllerRef ref) async {
  return getMockUserProfile();
}
