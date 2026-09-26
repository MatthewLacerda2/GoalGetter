/// Frontend domain model for the signed-in user (GET /me,
/// `backend/schemas/me.py`). `currentStreak` is user-wide, not per goal.
/// `member_since` still arrives and is ignored: nothing shows it (#178).
class UserProfile {
  final String id;
  final String name;
  final String email;
  final int currentStreak;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.currentStreak,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        currentStreak: json['current_streak'] as int,
      );
}
