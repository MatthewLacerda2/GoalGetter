/// Mock data source for the Home dashboard.
///
/// Mirrors the existing debug fixtures (see `mock_streak_screen.dart`,
/// `mock_resources_screen.dart`). Models a user 7 days into the app, learning
/// Italian. The elo history and recent lessons are consistent: each day's lesson
/// delta accumulates into that day's elo point (ending at `currentElo`).
/// See docs/backend_contract.md (GET /goals/{id}/dashboard).

/// A single completed lesson in the recent-lessons list.
class MockRecentLesson {
  final DateTime date;
  final double accuracy; // 0..100
  final int eloDelta; // signed elo change for that lesson

  MockRecentLesson({
    required this.date,
    required this.accuracy,
    required this.eloDelta,
  });
}

/// A single point on the elo-progress chart.
class MockEloPoint {
  final DateTime date;
  final int elo;

  MockEloPoint({required this.date, required this.elo});
}

/// Everything the Home dashboard needs for the active goal.
///
/// `goalName` is null when the user has no active goal yet (empty state).
class MockHomeData {
  final String? goalName;
  final int currentElo;
  final List<MockRecentLesson> recentLessons;
  final List<MockEloPoint> eloHistory;

  MockHomeData({
    required this.goalName,
    required this.currentElo,
    required this.recentLessons,
    required this.eloHistory,
  });
}

/// Simulates fetching the Home dashboard for the current active goal.
Future<MockHomeData> getMockHomeData() async {
  await Future.delayed(const Duration(milliseconds: 600));

  // 7 days of usage: one lesson per day, May 31 -> Jun 6, 2026.
  // (date, accuracy, eloDelta) — listed oldest first.
  final daily = <(DateTime, double, int)>[
    (DateTime(2026, 5, 31), 90, 16),
    (DateTime(2026, 6, 1), 80, 12),
    (DateTime(2026, 6, 2), 100, 20),
    (DateTime(2026, 6, 3), 50, -8),
    (DateTime(2026, 6, 4), 80, 14),
    (DateTime(2026, 6, 5), 100, 18),
    (DateTime(2026, 6, 6), 90, 10),
  ];

  const startingElo = 838;
  var elo = startingElo;
  final history = <MockEloPoint>[];
  final lessons = <MockRecentLesson>[];
  for (final (date, accuracy, delta) in daily) {
    elo += delta;
    history.add(MockEloPoint(date: date, elo: elo));
    lessons.add(
      MockRecentLesson(date: date, accuracy: accuracy, eloDelta: delta),
    );
  }

  // Recent lessons are shown most-recent first.
  final recent = lessons.reversed.toList();

  return MockHomeData(
    goalName: 'Learn Italian',
    currentElo: history.last.elo,
    recentLessons: recent,
    eloHistory: history,
  );
}
