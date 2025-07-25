import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final TimeOfDay startTime;
  final int durationMinutes;
  final String? goalId; // optional
  final List<int> weekdays; // 0=Sunday, 1=Monday, ..., 6=Saturday

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required this.durationMinutes,
    this.goalId,
    required this.weekdays,
  });

  // Example: serialization for storage (if needed)
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startTime': '${startTime.hour}:${startTime.minute}',
    'durationMinutes': durationMinutes,
    'goalId': goalId,
    'weekdays': weekdays,
  };

  // Example: deserialization (if needed)
  factory Task.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['startTime'] as String).split(':');
    return Task(
      id: json['id'],
      title: json['title'],
      startTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      durationMinutes: json['durationMinutes'],
      goalId: json['goalId'],
      weekdays: List<int>.from(json['weekdays']),
    );
  }
}