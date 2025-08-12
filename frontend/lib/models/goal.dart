import 'dart:convert';

class Goal {
  final String id;
  final String title;
  final String? description;

  Goal({
    required this.id,
    required this.title,
    this.description,
  });

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  static Goal fromJson(String source) => Goal.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}