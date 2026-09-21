/// One curated resource of `GET /resources`
/// (`backend/schemas/resource.py::ResourceItem`). Only YouTube items carry an
/// image.
class ResourceItem {
  const ResourceItem({
    required this.name,
    required this.description,
    required this.url,
    this.imageUrl,
  });

  factory ResourceItem.fromJson(Map<String, dynamic> json) => ResourceItem(
        name: json['name'] as String,
        description: json['description'] as String,
        url: json['url'] as String,
        imageUrl: json['image_url'] as String?,
      );

  final String name;
  final String description;
  final String url;
  final String? imageUrl;
}

/// The active goal's resources, grouped the way the backend groups them:
/// stored `pdf` is [books], stored `webpage` is [websites].
class GoalResources {
  const GoalResources({
    required this.youtube,
    required this.books,
    required this.websites,
  });

  factory GoalResources.fromJson(Map<String, dynamic> json) {
    List<ResourceItem> group(String key) => (json[key] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ResourceItem.fromJson)
        .toList(growable: false);
    return GoalResources(
      youtube: group('youtube'),
      books: group('books'),
      websites: group('websites'),
    );
  }

  final List<ResourceItem> youtube;
  final List<ResourceItem> books;
  final List<ResourceItem> websites;

  /// Nothing in any group: the background search has not finished (or found
  /// nothing). Not an error.
  bool get isEmpty => youtube.isEmpty && books.isEmpty && websites.isEmpty;
}
