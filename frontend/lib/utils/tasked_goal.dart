import 'goal_storage.dart';
import 'task_storage.dart';

class UnassignedGoalInfo {
  final String goalTitle;
  final String goalId;
  final int minutesMissing;

  UnassignedGoalInfo({
    required this.goalTitle,
    required this.goalId,
    required this.minutesMissing,
  });
}

/// Returns the first goal that does not have all its weekly hours assigned to tasks.
/// Returns null if all goals are fully assigned.
Future<UnassignedGoalInfo?> findUnassignedGoal() async {
  final goals = await GoalStorage.loadAll();

  for (final goal in goals) {
    final totalMinutes = await TaskStorage.getTotalDurationForGoal(goal.id);
    
    if (totalMinutes < goal.weeklyHours * 60) {
      // No tasks for this goal - missing all weekly hours
      final totalMinutesNeeded = (goal.weeklyHours * 60).round() - totalMinutes;
      return UnassignedGoalInfo(
        goalTitle: goal.title,
        goalId: goal.id,
        minutesMissing: totalMinutesNeeded,
      );
    }
  }

  // All goals are fully assigned
  return null;
}