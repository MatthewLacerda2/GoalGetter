/// Mock data source for the Home dashboard.
///
/// Mirrors the existing debug fixtures (see `mock_streak_screen.dart`,
/// `mock_resources_screen.dart`). The Home screen runs against this while the
/// app has no authenticated user during the refactor. Replace `getMockHomeData`
/// with a real API-backed fetch (active goal, elo history, lesson history) once
/// the backend endpoints exist.

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

  final now = DateTime(2026, 6, 6);

  // ~90 days of elo history so the 7/30/90 filters all have data.
  final history = <MockEloPoint>[];
  var elo = 820;
  for (var i = 90; i >= 0; i--) {
    // Gentle upward drift with some wobble (deterministic, no RNG).
    elo += ((i % 5) - 2) * 4 + 2;
    history.add(MockEloPoint(date: now.subtract(Duration(days: i)), elo: elo));
  }

  final recent = <MockRecentLesson>[
    MockRecentLesson(date: now, accuracy: 90, eloDelta: 14),
    MockRecentLesson(date: now.subtract(const Duration(days: 1)), accuracy: 70, eloDelta: 6),
    MockRecentLesson(date: now.subtract(const Duration(days: 2)), accuracy: 100, eloDelta: 18),
    MockRecentLesson(date: now.subtract(const Duration(days: 3)), accuracy: 50, eloDelta: -8),
    MockRecentLesson(date: now.subtract(const Duration(days: 4)), accuracy: 80, eloDelta: 10),
  ];

  return MockHomeData(
    goalName: 'Learn Italian',
    currentElo: history.last.elo,
    recentLessons: recent,
    eloHistory: history,
  );
}
