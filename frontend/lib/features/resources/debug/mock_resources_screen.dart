/// Simulates loading mock resources for the user's active learning goal.
///
/// Demo user: learning Italian. Resources are curated per active goal.
/// See docs/backend_contract.md (GET /resources?goalId=).
Future<Map<String, List<Map<String, String>>>> getMockResources() async {
  await Future.delayed(const Duration(milliseconds: 700));

  final youtube = [
    {
      'title': 'Learn Italian with Lucrezia',
      'description': 'Native-speaker lessons on everyday Italian, pronunciation, and culture.',
      'link': 'https://youtube.com',
    },
    {
      'title': 'Italy Made Easy — Beginner Course',
      'description': 'Structured beginner-to-intermediate series focused on speaking from day one.',
      'link': 'https://youtube.com',
    },
  ];

  final sites = [
    {
      'title': 'News in Slow Italian',
      'description': 'Current-events audio spoken slowly, with transcripts — great for listening practice.',
      'link': 'https://newsinslowitalian.com',
    },
    {
      'title': 'Reverso Context (IT)',
      'description': 'See real-world Italian sentences and translations in context for any word or phrase.',
      'link': 'https://context.reverso.net',
    },
  ];

  final books = [
    {
      'title': 'Italian Grammar in Practice (PDF)',
      'description': 'Exercise-driven guide covering essere/avere, articles, and verb conjugations.',
      'link': 'https://example.com',
    },
    {
      'title': 'Short Stories in Italian for Beginners (PDF)',
      'description': 'Graded readers with glossaries — build vocabulary through simple narratives.',
      'link': 'https://example.com',
    },
  ];

  return {
    'youtube': youtube,
    'sites': sites,
    'books': books,
  };
}
