import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/app/app.dart';
import 'package:http/http.dart' as http;

import '../app/app_harness.dart';
import '../contract/contract_client.dart';
import 'student.dart';

/// Golden tests (#226): each screen of the real app — its router, theme,
/// locale and fonts — drawn to a PNG and compared with the reference under
/// `references/`, pixel for pixel. A difference fails `make frontend` and
/// writes the reference, the new image and their diff to `failures/`.
///
/// `make front-goldens` redraws the references on purpose; the new PNGs are
/// part of the pull request's diff, which is where a reviewer sees what moved.

/// How a screen is drawn. Two looks cover both themes and a language other
/// than English on every screen, at half the images of each combination.
enum Look {
  lightEn(ThemeMode.light, 'en'),
  darkPt(ThemeMode.dark, 'pt');

  const Look(this.theme, this.language);

  final ThemeMode theme;
  final String language;
}

/// A phone in logical pixels, drawn at 1x: small files, same layout.
const Size phone = Size(390, 844);

/// One golden per [Look], named `references/<name>.<look>.png`. [show]
/// launches the app and brings it to the screen being photographed.
void goldenTest(
  String name,
  Future<void> Function(WidgetTester tester, Look look) show,
) {
  for (final look in Look.values) {
    testWidgets('$name (${look.name})', (tester) async {
      tester.view
        ..physicalSize = phone
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await show(tester, look);
      await _precacheImages(tester);
      await expectLater(
        find.byType(GoalGetterApp),
        matchesGoldenFile('references/$name.${look.name}.png'),
      );
      // Lets a reply held for the capture ([openApp]'s `slow`) land, so no
      // timer outlives the test.
      await tester.pump(_slowReply);
    });
  }
}

const Duration _slowReply = Duration(seconds: 1);

/// The real app over [studentReplies], drawn as [look]. Signed in unless
/// [signedIn] is false; the keys in [slow] answer a second later, and without
/// [settle] only the first frame is drawn.
Future<GoRouter> openApp(
  WidgetTester tester,
  Look look, {
  bool signedIn = true,
  Set<String> slow = const {},
  bool settle = true,
}) async {
  final (router, _) = await launchApp(
    tester,
    _backend(slow),
    stored: {
      'user_language': look.language,
      'theme_mode': look.theme.name,
      if (signedIn) ...{'access_token': 'a', 'current_goal_id': 'g1'},
    },
    settle: settle,
  );
  return router;
}

/// Opens the app and goes to [path], handing it [extra].
Future<void> openAt(
  WidgetTester tester,
  Look look,
  String path, {
  Object? extra,
  bool signedIn = true,
}) async {
  final router = await openApp(tester, look, signedIn: signedIn);
  router.go(path, extra: extra);
  await tester.pumpAndSettle();
}

http.Client _backend(Set<String> slow) => contractClient((request) async {
      final key =
          '${request.method} ${request.url.path.replaceFirst('/api/v1', '')}';
      if (slow.contains(key)) await Future<void>.delayed(_slowReply);
      final (status, body) =
          studentReplies[key] ?? (599, '{"detail": "no route"}');
      return http.Response(body, status);
    });

/// An image decodes outside fake time, so it is loaded for real before the
/// capture — otherwise the start screen's icon is a blank box.
Future<void> _precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
}
