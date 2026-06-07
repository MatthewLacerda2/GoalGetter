import 'package:goal_getter/features/goals/domain/goal.dart';

/// Mock goals for the demo user (7 days into the app). The "Learn Italian"
/// goal is active and matches the Home dashboard fixtures (mock_home_screen).
/// Stands in for GET /goals until the backend exists.
Future<List<Goal>> getMockGoals() async {
  await Future.delayed(const Duration(milliseconds: 500));

  return [
    Goal(
      id: 'goal_italian',
      name: 'Learn Italian',
      description:
          'Reach conversational fluency in Italian — hold a 10-minute chat '
          'about daily life, food, and travel without switching to English.',
      createdAt: DateTime(2026, 5, 31),
      currentElo: 920,
      isActive: true,
    ),
    Goal(
      id: 'goal_chess',
      name: 'Master Chess Openings',
      description:
          'Build a solid opening repertoire (Italian Game, Caro-Kann) and stop '
          'losing games in the first 10 moves.',
      createdAt: DateTime(2026, 6, 2),
      currentElo: 760,
      isActive: false,
    ),
    Goal(
      id: 'goal_spanish',
      name: 'Conversational Spanish',
      description:
          'Refresh rusty Spanish for an upcoming trip to Madrid — focus on '
          'restaurants, directions, and small talk.',
      createdAt: DateTime(2026, 6, 4),
      currentElo: 1040,
      isActive: false,
    ),
  ];
}
