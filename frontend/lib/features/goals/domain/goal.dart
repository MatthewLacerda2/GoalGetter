/// Frontend domain model for a learning goal: one item of `GET /goals`
/// (`backend/schemas/goal.py::GoalResponse`).
///
/// `currentElo` is the rating for this goal; `isActive` marks the goal driving
/// home, resources and the tutor (`students.current_goal_id` on the backend).
/// `updatedAt` moves whenever the goal row changes, the rating after a lesson
/// included; activating a goal does not move it.
class Goal {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int currentElo;
  final bool isActive;

  const Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.currentElo,
    required this.isActive,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        currentElo: json['current_elo'] as int,
        isActive: json['is_active'] as bool,
      );
}
