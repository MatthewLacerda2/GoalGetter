/// Frontend domain models for GET /home (`backend/schemas/home.py`).
library;

/// A lesson in the recent-lessons list: the answers the backend marked as one
/// batch. [date] is the student's calendar date they were given.
///
/// There is no elo delta: a lesson's rating change has had no stored history
/// since the backend stopped keeping a `lessons` row, and gets one with #62.
class RecentLesson {
  final String lessonId;
  final DateTime date;
  final double accuracy; // 0..100
  final int durationSeconds;

  const RecentLesson({
    required this.lessonId,
    required this.date,
    required this.accuracy,
    required this.durationSeconds,
  });

  factory RecentLesson.fromJson(Map<String, dynamic> json) => RecentLesson(
        lessonId: json['lesson_id'] as String,
        date: DateTime.parse(json['date'] as String),
        accuracy: (json['accuracy'] as num).toDouble(),
        durationSeconds: json['duration_seconds'] as int,
      );
}

/// The active goal's dashboard. `currentStreak` is user-wide, not per goal.
class HomeDashboard {
  final String goalName;
  final int currentElo;
  final int currentStreak;
  final List<RecentLesson> recentLessons; // newest first

  const HomeDashboard({
    required this.goalName,
    required this.currentElo,
    required this.currentStreak,
    required this.recentLessons,
  });

  factory HomeDashboard.fromJson(Map<String, dynamic> json) => HomeDashboard(
        goalName: json['goal_name'] as String,
        currentElo: json['current_elo'] as int,
        currentStreak: json['current_streak'] as int,
        recentLessons: (json['recent_lessons'] as List)
            .cast<Map<String, dynamic>>()
            .map(RecentLesson.fromJson)
            .toList(growable: false),
      );
}
