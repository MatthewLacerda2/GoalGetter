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
}