import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/theme/app_theme.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:goal_getter/features/lessons/presentation/screens/finish_lesson_screen.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import '../api_fake.dart';
import 'lesson_json.dart';

/// A one-question lesson, answered right, handed to the real finish route
/// under the app's own theme: what the student sees at the end of a lesson.
Future<void> finishALesson(WidgetTester tester) async {
  final fake = ApiFake({
    startKey: [(201, lessonJson(1))],
    answersKey: [(200, evaluationJson)],
  });
  final router = GoRouter(
    initialLocation: AppRoutes.lesson,
    routes: [
      GoRoute(path: AppRoutes.lesson, builder: (_, __) => const LessonScreen()),
      GoRoute(
        path: AppRoutes.lessonFinish,
        builder: (_, state) =>
            FinishLessonScreen(evaluation: state.extra! as LessonEvaluation),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    retry: noAutomaticRetry,
    overrides: await fake.overrides(),
    child: MaterialApp.router(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('a'));
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton)); // Enter
  await tester.pump();
  await tester.tap(find.byType(ElevatedButton)); // Continue
  await tester.pumpAndSettle();
}

/// The tile whose header reads [title]: its border colour, icon and value.
(Color, IconData?, String?) tile(WidgetTester tester, String title) {
  final stat = find.ancestor(
    of: find.text(title),
    matching: find.byType(StatWidget),
  );
  final box = tester
      .widget<Container>(
        find.descendant(of: stat, matching: find.byType(Container)).first,
      )
      .decoration! as BoxDecoration;
  final icon = tester.widget<Icon>(
    find.descendant(of: stat, matching: find.byType(Icon)),
  );
  final texts = tester
      .widgetList<Text>(find.descendant(of: stat, matching: find.byType(Text)))
      .map((t) => t.data)
      .toList();
  expect(icon.color, (box.border! as Border).top.color);
  return ((box.border! as Border).top.color, icon.icon, texts.last);
}

void main() {
  // #222: the route carries the lesson's evaluation and the finish screen
  // formats it. Nothing the student sees may change with that move.
  testWidgets('the finish screen reads as it always has', (tester) async {
    await finishALesson(tester);
    final context = tester.element(find.byType(FinishLessonScreen));
    final scheme = Theme.of(context).colorScheme;

    expect(find.text('Lesson complete!'), findsOneWidget);
    final trophy = tester.widget<Icon>(find.byIcon(Icons.check_circle).first);
    expect(trophy.size, 140);
    expect(trophy.color, scheme.secondary);

    expect(tile(tester, 'TIME'), (scheme.primary, Icons.timer, '00:06'));
    expect(
      tile(tester, 'ACCURACY'),
      (AppTheme.success, Icons.check_circle, '67%'),
    );
    expect(tile(tester, 'ELO'), (scheme.secondary, Icons.trending_up, '+12'));
  });
}
