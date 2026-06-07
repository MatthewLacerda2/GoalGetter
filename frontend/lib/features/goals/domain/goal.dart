/// Frontend domain model for a learning goal.
///
/// Replaces the generated `client_sdk` `GoalListItem` (deprecated). `currentElo`
/// is the chess-like rating for this goal; `isActive` marks the goal currently
/// driving the Home dashboard. See docs/backend_contract.md (GET /goals).
class Goal {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final int currentElo;
  final bool isActive;

  const Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.currentElo,
    required this.isActive,
  });
}
