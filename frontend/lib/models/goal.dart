import 'dart:convert';

class Goal {
  final String id;
  final String title;
  final String? description;
  final double weeklyHours;
  final double totalWeekSpent;

  Goal({
    required this.id,
    required this.title,
    this.description,
    required this.weeklyHours,
    this.totalWeekSpent = 0.0,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      weeklyHours: map['weeklyHours'].toDouble(),
      totalWeekSpent: (map['totalWeekSpent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weeklyHours': weeklyHours,
      'totalWeekSpent': totalWeekSpent,
    };
  }

  static Goal fromJson(String source) => Goal.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}