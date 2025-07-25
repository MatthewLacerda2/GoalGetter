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
  final tasks = await TaskStorage.loadAll();

  for (final goal in goals) {
    // Find all tasks assigned to this goal
    final goalTasks = tasks.where((t) => t.goalId == goal.id).toList();

    if (goalTasks.isEmpty) {
      // No tasks for this goal - missing all weekly hours
      final totalMinutesNeeded = (goal.weeklyHours * 60).round();
      return UnassignedGoalInfo(
        goalTitle: goal.title,
        goalId: goal.id,
        minutesMissing: totalMinutesNeeded,
      );
    }

    // Sum up total weekly minutes for this goal
    int totalMinutes = 0;
    for (final task in goalTasks) {
      totalMinutes += task.durationMinutes * task.weekdays.length;
    }
    final totalMinutesNeeded = (goal.weeklyHours * 60).round();
    final minutesMissing = totalMinutesNeeded - totalMinutes;

    if (minutesMissing > 0) {
      // Not enough hours assigned
      return UnassignedGoalInfo(
        goalTitle: goal.title,
        goalId: goal.id,
        minutesMissing: minutesMissing,
      );
    }
  }

  // All goals are fully assigned
  return null;
}