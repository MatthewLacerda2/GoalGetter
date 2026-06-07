/// A lightweight study plan shown after onboarding questions.
///
/// Intentionally minimal: the goal's name plus a short, AI-generated summary
/// (markdown) of what the user will work on. The user then confirms or
/// rejects it (rejecting returns to the goal prompt).
class StudyPlan {
  final String goalName;

  /// Short markdown blurb, e.g. "You'll focus on **x**, **y** and **z**".
  final String description;

  const StudyPlan({required this.goalName, required this.description});
}
