import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal.dart';
import 'package:uuid/uuid.dart';
import 'task_storage.dart';

class GoalStorage {
  static const String _goalsKey = 'goals';

  static Future<List<Goal>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString(_goalsKey);
    if (goalsJson == null) return [];
    final List<dynamic> decoded = json.decode(goalsJson);
    final goals = decoded.map((e) => Goal.fromMap(e)).toList();
    
    // Calculate total tasked hours for each goal
    final updatedGoals = <Goal>[];
    for (final goal in goals) {
      final totalMinutes = await TaskStorage.getTotalDurationForGoal(goal.id);
      final totalHours = totalMinutes / 60.0;
      updatedGoals.add(Goal(
        id: goal.id,
        title: goal.title,
        description: goal.description,
        weeklyHours: goal.weeklyHours,
        totalTaskedHours: totalHours,
      ));
    }
    
    return updatedGoals;
  }

  static Future<Goal?> loadById(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveNew(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final newGoal = goal.id.isEmpty
        ? goal.copyWith(id: const Uuid().v4())
        : goal;
    all.add(newGoal);
    await prefs.setString(_goalsKey, json.encode(all.map((g) => g.toMap()).toList()));
  }

  static Future<void> saveById(String id, Goal updatedGoal) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final idx = all.indexWhere((g) => g.id == id);
    if (idx != -1) {
      all[idx] = updatedGoal;
      await prefs.setString(_goalsKey, json.encode(all.map((g) => g.toMap()).toList()));
    }
  }

  static Future<void> deleteGoal(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.removeWhere((g) => g.id == id);
    await prefs.setString(_goalsKey, json.encode(all.map((g) => g.toMap()).toList()));
    
    // Delete all tasks that have this goal assigned
    final tasks = await TaskStorage.loadAll();
    for (final task in tasks) {
      if (task.goalId == id) {
        await TaskStorage.deleteTask(task.id);
      }
    }
  }

  static Future<void> deleteAllGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_goalsKey);
  }
}

extension GoalCopyWith on Goal {
  Goal copyWith({
    String? id,
    String? title,
    String? description,
    double? weeklyHours,
    double? totalTaskedHours,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      totalTaskedHours: totalTaskedHours ?? this.totalTaskedHours,
    );
  }
}