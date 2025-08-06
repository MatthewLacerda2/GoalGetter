import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskStorage {
  static const String _tasksKey = 'tasks';

  // Save a new task
  static Future<void> saveNew(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await loadAll();
    tasks.add(task);
    final tasksJson = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(tasksJson));
  }

  // Load all tasks for a given weekday (0=Sunday, ..., 6=Saturday)
  static Future<List<Task>> loadByDay(int weekday) async {
    final tasks = await loadAll();
    return tasks.where((task) => task.weekdays.contains(weekday)).toList();
  }

  // Delete a task by its ID
  static Future<void> deleteTask(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await loadAll();
    tasks.removeWhere((task) => task.id == taskId);
    final tasksJson = tasks.map((t) => t.toJson()).toList();
    await prefs.setString(_tasksKey, jsonEncode(tasksJson));
  }

  // Load all tasks from storage
  static Future<List<Task>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tasksKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Task.fromJson(json)).toList();
  }

  // Save a task by its ID (for editing existing tasks)
  static Future<void> saveById(String taskId, Task updatedTask) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = await loadAll();
    
    // Find and replace the task with the matching ID
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      tasks[taskIndex] = updatedTask;
      final tasksJson = tasks.map((t) => t.toJson()).toList();
      await prefs.setString(_tasksKey, jsonEncode(tasksJson));
    }
  }

  // Get total duration of tasks for a specific goal
  //TODO: now that we have the totalTaskedHours in the goal, we can remove this function
  static Future<int> getTotalDurationForGoal(String goalId) async {
    final tasks = await loadAll();
    int total = 0;
    for (final task in tasks) {
      if (task.goalId == goalId) {
        total += task.durationMinutes * task.weekdays.length;
      }
    }
    return total;
  }
}