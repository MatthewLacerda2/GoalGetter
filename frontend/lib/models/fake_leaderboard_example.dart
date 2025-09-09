//INFO: this is just a placeholder model. Once we get the client_sdk, this'll be deleted
class FakeLeaderboardExample {
  final String name;
  final int score;

  FakeLeaderboardExample({required this.name, required this.score});
}

class FakeLeaderboardData {
  static List<Map<String, dynamic>> getSampleData() {
    return [
      {'name': 'Washington', 'xpAmount': 400},
      {'name': 'Lendacerda', 'xpAmount': 300},
      {'name': 'David Quilan', 'xpAmount': 260},
      {'name': 'Ana Paula', 'xpAmount': 220},
      {'name': 'Fernandinho', 'xpAmount': 180},
    ];
  }

  static String getCurrentUsername() {
    return 'Lendacerda'; // This will be highlighted in the leaderboard
  }

  static int getStartingPosition() {
    return 7; // Starting position for the leaderboard
  }
}

