import 'package:goal_getter/features/profile/domain/user_profile.dart';

/// Mock signed-in user: "Marco", 7 days into the app with a 7-day streak.
/// Stands in for GET /me until the backend exists.
Future<UserProfile> getMockUserProfile() async {
  await Future.delayed(const Duration(milliseconds: 400));

  return UserProfile(
    id: 'user_marco',
    name: 'Marco Rossi',
    email: 'marco.rossi@example.com',
    memberSince: DateTime(2026, 5, 31),
    currentStreak: 7,
  );
}
