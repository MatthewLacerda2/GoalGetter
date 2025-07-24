// frontend/goal_getter/lib/models/goal.dart

import 'dart:convert';

class Goal {
  final String id;
  final String title;
  final String description;
  final double weeklyHours;
  final double totalHours;
  final List<bool> selectedDays;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.weeklyHours,
    required this.totalHours,
    required this.selectedDays,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      weeklyHours: map['weeklyHours'].toDouble(),
      totalHours: map['totalHours'].toDouble(),
      selectedDays: List<bool>.from(map['selectedDays']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weeklyHours': weeklyHours,
      'totalHours': totalHours,
      'selectedDays': selectedDays,
    };
  }

  static Goal fromJson(String source) => Goal.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}