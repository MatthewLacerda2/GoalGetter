/// Simulates loading mock resources for the user's active learning goal.
///
/// Demo user: learning Italian. Resources are curated per active goal.
/// See docs/backend_contract.md (GET /resources?goalId=).
Future<Map<String, List<Map<String, String>>>> getMockResources() async {
  await Future.delayed(const Duration(milliseconds: 700));

  // Video thumbnails use a stable placeholder image service; site logos use
  // Google's favicon service. (Mock only — see docs/backend_contract.md.)
  final youtube = [
    {
      'title': 'Learn Italian with Lucrezia',
      'description': 'Native-speaker lessons on everyday Italian, pronunciation, and culture.',
      'link': 'https://youtube.com',
      'image': 'https://picsum.photos/seed/italian-lucrezia/200/200',
    },
    {
      'title': 'Italy Made Easy — Beginner Course',
      'description': 'Structured beginner-to-intermediate series focused on speaking from day one.',
      'link': 'https://youtube.com',
      'image': 'https://picsum.photos/seed/italy-made-easy/200/200',
    },
  ];

  final sites = [
    {
      'title': 'News in Slow Italian',
      'description': 'Current-events audio spoken slowly, with transcripts — great for listening practice.',
      'link': 'https://newsinslowitalian.com',
      'image': 'https://www.google.com/s2/favicons?domain=newsinslowitalian.com&sz=128',
    },
    {
      'title': 'Reverso Context (IT)',
      'description': 'See real-world Italian sentences and translations in context for any word or phrase.',
      'link': 'https://context.reverso.net',
      'image': 'https://www.google.com/s2/favicons?domain=reverso.net&sz=128',
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
