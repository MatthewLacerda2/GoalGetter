class MockStreakData {
  final int currentStreak;
  final bool? monday;
  final bool? tuesday;
  final bool? wednesday;
  final bool? thursday;
  final bool? friday;
  final bool? saturday;
  final bool? sunday;

  MockStreakData({
    required this.currentStreak,
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
    this.sunday,
  });
}

/// Simulates fetching current week streak data from the database.
///
/// Demo user: 7 days into the app — a full 7-day streak (every day this week
/// completed). See docs/backend_contract.md (GET /streak).
Future<MockStreakData> getMockStreakData() async {
  await Future.delayed(const Duration(milliseconds: 600));

  return MockStreakData(
    currentStreak: 7,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true,
    saturday: true,
    sunday: true,
  );
}
