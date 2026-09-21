import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/features/resources/domain/resource_item.dart';
import 'package:goal_getter/features/resources/presentation/screens/resources_screen.dart';

import '../fake_backend.dart';

String item(String name, {String? image}) => jsonEncode({
      'name': name,
      'description': 'About $name',
      'url': 'https://example.com/$name',
      'image_url': image,
    });

final _empty = '{"youtube": [], "books": [], "websites": []}';
final _full = '{"youtube": [${item('Intro video', image: 'https://i.test/1')}],'
    ' "books": [${item('Go book')}, ${item('Go spec')}], "websites": []}';

Future<FakeBackend> open(WidgetTester tester, List<Reply> replies) async {
  final backend = FakeBackend({'GET /resources': replies});
  await backend.start();
  await pumpRouted(
    tester,
    backend,
    [GoRoute(path: '/resources', builder: (_, __) => const ResourcesScreen())],
    initial: '/resources',
  );
  return backend;
}

void main() {
  test('resources keep the backend grouping, image only where given', () {
    final resources = GoalResources.fromJson(
      jsonDecode(_full) as Map<String, dynamic>,
    );

    expect(resources.youtube.single.imageUrl, 'https://i.test/1');
    expect(resources.books.map((r) => r.name), ['Go book', 'Go spec']);
    expect(resources.books.first.imageUrl, isNull);
    expect(resources.websites, isEmpty);
    expect(resources.isEmpty, isFalse);
  });

  testWidgets('loaded resources show one tab per kind', (tester) async {
    await open(tester, [(200, _full)]);

    expect(find.text('Videos (1)'), findsOneWidget);
    expect(find.text('Guides (2)'), findsOneWidget);
    expect(find.text('Intro video'), findsOneWidget);
  });

  testWidgets('three empty lists say the search is still running',
      (tester) async {
    await open(tester, [(200, _empty)]);

    expect(find.text('Still looking for resources'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a failed load is an error with a retry, not the empty state',
      (tester) async {
    await open(tester, [(500, '{"detail": "Boom"}'), (200, _full)]);

    expect(find.text('Could not load resources'), findsOneWidget);
    expect(find.text('Still looking for resources'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Intro video'), findsOneWidget);
  });

  testWidgets('no active goal offers to pick one', (tester) async {
    await open(tester, [(404, '{"detail": "No active goal"}')]);

    expect(find.text('No active goal'), findsOneWidget);
    expect(find.text('Pick a goal'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
