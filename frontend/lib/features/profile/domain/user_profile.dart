/// Frontend domain model for the signed-in user (GET /me,
/// `backend/schemas/me.py`). `currentStreak` is user-wide, not per goal.
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

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        memberSince: DateTime.parse(json['member_since'] as String),
        currentStreak: json['current_streak'] as int,
      );
}
