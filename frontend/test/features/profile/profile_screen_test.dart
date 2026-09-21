import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/profile/presentation/screens/profile_screen.dart';

import '../api_fake.dart';

const meJson = '{"id": "s1", "name": "Fictitious Claude",'
    ' "email": "claude@example.com",'
    ' "member_since": "2026-09-01T10:00:00", "current_streak": 9}';

Future<void> pumpProfile(WidgetTester tester, (int, String) me) async {
  final fake = ApiFake({
    'GET /me': [me],
    'GET /goals': [(200, '[]')],
  });
  await pumpScreen(tester, await fake.overrides(), ProfileScreen());
  // The goals count may still come from a delayed mock: let it resolve.
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('the header reads GET /me', (tester) async {
    await pumpProfile(tester, (200, meJson));

    expect(find.text('Fictitious Claude'), findsOneWidget);
    expect(find.text('claude@example.com'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('Member since Sep 1, 2026'), findsOneWidget);
  });

  testWidgets('a failed GET /me says so, with a retry', (tester) async {
    await pumpProfile(tester, (500, '{"detail": "boom"}'));

    expect(find.text('Could not load your profile: boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
