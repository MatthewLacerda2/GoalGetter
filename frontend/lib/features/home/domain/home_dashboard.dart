/// Frontend domain models for GET /home (`backend/schemas/home.py`).
library;

/// A finished lesson in the recent-lessons list. [date] is the server's local
/// date the lesson was answered.
class RecentLesson {
  final String lessonId;
  final DateTime date;
  final double accuracy; // 0..100
  final int eloDelta;
  final int durationSeconds;

  const RecentLesson({
    required this.lessonId,
    required this.date,
    required this.accuracy,
    required this.eloDelta,
    required this.durationSeconds,
  });

  factory RecentLesson.fromJson(Map<String, dynamic> json) => RecentLesson(
        lessonId: json['lesson_id'] as String,
        date: DateTime.parse(json['date'] as String),
        accuracy: (json['accuracy'] as num).toDouble(),
        eloDelta: json['elo_delta'] as int,
        durationSeconds: json['duration_seconds'] as int,
      );
}

/// The goal's rating at the end of one day that had a lesson.
class EloPoint {
  final DateTime date;
  final int elo;

  const EloPoint({required this.date, required this.elo});

  factory EloPoint.fromJson(Map<String, dynamic> json) => EloPoint(
        date: DateTime.parse(json['date'] as String),
        elo: json['elo'] as int,
      );
}

/// The active goal's dashboard. `currentStreak` is user-wide, not per goal.
class HomeDashboard {
  final String goalName;
  final int currentElo;
  final int currentStreak;
  final List<RecentLesson> recentLessons; // newest first
  final List<EloPoint> eloHistory; // oldest first

  const HomeDashboard({
    required this.goalName,
    required this.currentElo,
    required this.currentStreak,
    required this.recentLessons,
    required this.eloHistory,
  });

  factory HomeDashboard.fromJson(Map<String, dynamic> json) => HomeDashboard(
        goalName: json['goal_name'] as String,
        currentElo: json['current_elo'] as int,
        currentStreak: json['current_streak'] as int,
        recentLessons: (json['recent_lessons'] as List)
            .cast<Map<String, dynamic>>()
            .map(RecentLesson.fromJson)
            .toList(growable: false),
        eloHistory: (json['elo_history'] as List)
            .cast<Map<String, dynamic>>()
            .map(EloPoint.fromJson)
            .toList(growable: false),
      );
}
