import 'dart:convert';

class Goal {
  final String id;
  final String title;
  final String description;
  final double weeklyHours;
  final double totalHours;
  final double totalWeekSpent;
  final double totalSpent;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.weeklyHours,
    required this.totalHours,
    this.totalWeekSpent = 0.0,
    this.totalSpent = 0.0,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      weeklyHours: map['weeklyHours'].toDouble(),
      totalHours: map['totalHours'].toDouble(),
      totalWeekSpent: (map['totalWeekSpent'] ?? 0.0).toDouble(),
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weeklyHours': weeklyHours,
      'totalHours': totalHours,
      'totalWeekSpent': totalWeekSpent,
      'totalSpent': totalSpent,
    };
  }

  static Goal fromJson(String source) => Goal.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}