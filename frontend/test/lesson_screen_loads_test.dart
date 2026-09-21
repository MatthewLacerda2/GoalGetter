import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// Reproduction: the lesson screen must leave its loading state once the
/// (mocked) questions resolve. It currently spins forever.
void main() {
  testWidgets('lesson screen leaves the spinner and shows a question',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LessonScreen(),
        ),
      ),
    );

    // The mock source resolves after 500ms.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'still loading after the mock questions resolved');
    expect(find.textContaining('Italian'), findsWidgets);
  });
}
