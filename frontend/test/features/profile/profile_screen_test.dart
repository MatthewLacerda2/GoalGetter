import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/profile/presentation/screens/profile_screen.dart';

import '../api_fake.dart';

const meJson = '{"id": "s1", "name": "Fictitious Claude",'
    ' "email": "claude@example.com",'
    ' "member_since": "2026-09-01T10:00:00", "current_streak": 9,'
    ' "language": "en"}';

Future<ApiFake> pumpProfile(WidgetTester tester, (int, String) me) async {
  final fake = ApiFake({
    'GET /me': [me],
  });
  await pumpScreen(tester, await fake.overrides(), ProfileScreen());
  return fake;
}

Future<void> pickGerman(WidgetTester tester) async {
  await tester.tap(find.text('Language'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Deutsch'));
  await tester.pumpAndSettle();
}

void main() {
  // No avatar, name, email, goal count or streak: the page is settings only,
  // and creating a goal lives on the goals list.
  testWidgets('the page has no header and no create button', (tester) async {
    final fake = await pumpProfile(tester, (200, meJson));

    expect(fake.requests, isEmpty, reason: 'nothing on it needs GET /me');
    expect(find.text('Fictitious Claude'), findsNothing);
    expect(find.byIcon(Icons.local_fire_department), findsNothing);
    expect(find.text('Manage goals'), findsOneWidget);
    expect(find.text('View, switch, and delete'), findsNothing);
    expect(find.text('Create new goal'), findsNothing);
  });

  // The request carries X-Student-Language (ApiClient), so a GET /me right
  // after the pick is what tells the backend at once (#172).
  testWidgets('picking a language reads GET /me', (tester) async {
    final fake = await pumpProfile(tester, (200, meJson));
    expect(fake.count('GET /me'), 0);

    await pickGerman(tester);

    expect(fake.count('GET /me'), 1);
  });

  testWidgets('a failed GET /me after a pick shows nothing', (tester) async {
    final fake = await pumpProfile(tester, (500, '{"detail": "boom"}'));

    await pickGerman(tester);

    expect(fake.count('GET /me'), 1);
    expect(find.text('boom'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
