/// Frontend domain model for the signed-in user.
///
/// `currentStreak` is user-wide (not per goal). See docs/backend_contract.md
/// (GET /me).
class UserProfile {
  final String id;
  final String name;
  final String email;
  final DateTime memberSince;
  final int currentStreak;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.memberSince,
    required this.currentStreak,
  });
}
