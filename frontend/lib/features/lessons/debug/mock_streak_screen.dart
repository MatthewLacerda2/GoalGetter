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
Future<MockStreakData> getMockStreakData() async {
  await Future.delayed(const Duration(milliseconds: 600));
  
  // Return a sample streak with some days active (e.g. Mon-Fri)
  return MockStreakData(
    currentStreak: 5,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true, // Assuming today is Friday and completed
    saturday: null, // Future days are null (not colored yet)
    sunday: null,
  );
}
