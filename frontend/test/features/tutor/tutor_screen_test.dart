import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/presentation/screens/tutor_screen.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import 'fake_tutor_api.dart';

Future<void> pumpTutor(WidgetTester tester, FakeTutorApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tutorApiProvider.overrideWithValue(api)],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TutorScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an exchange shows its prompt, its replies, and one heart', (
    tester,
  ) async {
    await pumpTutor(tester, FakeTutorApi([exchange(1, liked: true)]));
    expect(find.text('prompt 1'), findsOneWidget);
    expect(find.text('reply 1.a'), findsOneWidget);
    expect(find.text('reply 1.b'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('tapping the heart likes the reply', (tester) async {
    await pumpTutor(tester, FakeTutorApi([exchange(1)]));
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  // A failed send is an action: a snackbar over the chat, which keeps the
  // bubble and gives the text back (#98).
  testWidgets('a failed send is a snackbar that gives the text back', (
    tester,
  ) async {
    await pumpTutor(tester, FakeTutorApi([])..sendError = geminiDown);
    await tester.enterText(find.byType(TextField), 'ciao');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('The model is overloaded'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'ciao');
  });

  testWidgets('a sent message shows the reply bubbles', (tester) async {
    await pumpTutor(tester, FakeTutorApi([]));
    await tester.enterText(find.byType(TextField), 'ciao');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Ciao!'), findsOneWidget);
    expect(find.text('Pronto?'), findsOneWidget);
  });
}
