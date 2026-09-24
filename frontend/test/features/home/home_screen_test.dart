import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/features/home/presentation/screens/home_screen.dart';

import '../api_fake.dart';

String homeJson() {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  return '{"goal_name": "Learn Go", "current_elo": 1042, "current_streak": 5,'
      ' "recent_lessons": [{"lesson_id": "l1", "date": "$today",'
      ' "accuracy": 80.0, "elo_delta": 14, "duration_seconds": 95}],'
      ' "elo_history": [{"date": "$today", "elo": 1042}]}';
}

Future<void> pumpHome(WidgetTester tester, (int, String) reply) async {
  final fake = ApiFake({'GET /home': [reply]});
  await pumpScreen(tester, await fake.overrides(), const HomeScreen());
}

void main() {
  testWidgets('shows the dashboard from GET /home', (tester) async {
    await pumpHome(tester, (200, homeJson()));

    expect(find.text('Learn Go'), findsOneWidget);
    expect(find.text('1042'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // streak
    expect(find.text('+14'), findsOneWidget);
    expect(find.text('1:35'), findsOneWidget);
  });

  testWidgets('404 No active goal is the empty state', (tester) async {
    await pumpHome(tester, (404, '{"detail": "No active goal"}'));

    expect(find.text('No active goal yet'), findsOneWidget);
    expect(find.text('Create Goal'), findsOneWidget);
  });

  // A screen that could not load says so where the screen would have been:
  // a snackbar would fade and leave nothing to press (#98).
  testWidgets('a failed load is an inline failure with a retry', (
    tester,
  ) async {
    await pumpHome(tester, (500, '{"detail": "boom"}'));

    expect(find.byType(FailureView), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Could not load your dashboard'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
