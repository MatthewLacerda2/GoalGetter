/// The study-plan preview of `POST /goals/study-plan`: the goal's name plus a
/// short, AI-generated summary (markdown). The student confirms it (which
/// creates the goal) or starts over. Nothing is persisted until they confirm.
class StudyPlan {
  final String goalName;

  /// Short markdown blurb, e.g. "You'll focus on **x**, **y** and **z**".
  final String description;

  const StudyPlan({required this.goalName, required this.description});

  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
    goalName: json['goal_name'] as String,
    description: json['description'] as String,
  );
}
