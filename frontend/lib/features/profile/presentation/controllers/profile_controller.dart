import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/features/profile/domain/user_profile.dart';
import 'package:goal_getter/features/profile/debug/mock_profile.dart';

/// Provides the signed-in user's profile. Mock-backed (plain FutureProvider, no
/// codegen) while the backend doesn't exist. See docs/backend_contract.md
/// (GET /me).
final profileControllerProvider = FutureProvider<UserProfile>((ref) async {
  return getMockUserProfile();
});
