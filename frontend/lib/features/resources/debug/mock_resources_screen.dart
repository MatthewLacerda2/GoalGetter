
/// Simulates loading mock resources for the user's active learning goal.
Future<Map<String, List<Map<String, String>>>> getMockResources() async {
  await Future.delayed(const Duration(milliseconds: 700));

  final youtube = [
    {
      'title': 'Flutter Crash Course for Beginners 2026',
      'description': 'A complete 3-hour walkthrough starting from absolute scratch up to state management.',
      'link': 'https://youtube.com',
    },
    {
      'title': 'How to Build Beautiful UIs in Flutter',
      'description': 'Advanced tips on layouts, custom painters, and Material 3 design systems.',
      'link': 'https://youtube.com',
    },
  ];

  final sites = [
    {
      'title': 'Flutter Official Documentation',
      'description': 'The official documentation, APIs reference, and cookbooks for Dart and Flutter.',
      'link': 'https://flutter.dev',
    },
    {
      'title': 'Dart Packages (pub.dev)',
      'description': 'Find open-source plugins, utilities, and packages shared by the Flutter community.',
      'link': 'https://pub.dev',
    },
  ];

  final books = [
    {
      'title': 'Dart & Flutter Design Patterns',
      'description': 'A comprehensive PDF guide explaining architecture, clean code, and design patterns.',
      'link': 'https://flutter.dev',
    },
    {
      'title': 'Flutter Cookbook (PDF Guide)',
      'description': 'Short, recipes-based tutorials answering common layout and interaction questions.',
      'link': 'https://flutter.dev',
    },
  ];

  return {
    'youtube': youtube,
    'sites': sites,
    'books': books,
  };
}
