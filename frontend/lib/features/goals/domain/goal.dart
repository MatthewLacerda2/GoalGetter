/// Frontend domain model for a learning goal: one item of `GET /goals`
/// (`backend/schemas/goal.py::GoalResponse`).
///
/// `currentElo` is the rating for this goal; `isActive` marks the goal driving
/// home, resources and the tutor (`students.current_goal_id` on the backend).
/// `created_at` and `updated_at` still arrive and are ignored: nothing shows
/// them.
class Goal {
  final String id;
  final String name;
  final String description;
  final int currentElo;
  final bool isActive;

  const Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.currentElo,
    required this.isActive,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        currentElo: json['current_elo'] as int,
        isActive: json['is_active'] as bool,
      );
}
