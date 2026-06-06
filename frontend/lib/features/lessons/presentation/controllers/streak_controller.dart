import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:goal_getter/features/lessons/debug/mock_streak_screen.dart';

part 'streak_controller.g.dart';

@riverpod
Future<dynamic> streak(StreakRef ref) async {
  return await getMockStreakData();
}
