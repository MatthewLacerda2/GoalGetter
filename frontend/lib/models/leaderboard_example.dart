class LeaderboardExample {
  final String name;
  final int score;

  LeaderboardExample({required this.name, required this.score});
}

class LeaderboardData {
  static List<Map<String, dynamic>> getSampleData() {
    return [
      {'name': 'ELEN', 'xpAmount': 400},
      {'name': 'Jasmine', 'xpAmount': 300},
      {'name': 'Ana Larissa', 'xpAmount': 260},
      {'name': 'Maria', 'xpAmount': 220},
      {'name': 'Carlos', 'xpAmount': 180},
    ];
  }

  static String getCurrentUsername() {
    return 'Jasmine'; // This will be highlighted in the leaderboard
  }

  static int getStartingPosition() {
    return 19; // Starting position for the leaderboard
  }
}

