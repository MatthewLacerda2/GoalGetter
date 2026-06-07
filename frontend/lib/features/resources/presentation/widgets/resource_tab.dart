import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A tab of curated resources. Each item is a clean white card with an optional
/// thumbnail/logo, a title + description, and a trailing open-in-new link icon
/// (to read as clickable). Tapping opens the link.
class ResourceTab extends StatelessWidget {
  final List<Map<String, String>> resources;

  const ResourceTab({super.key, required this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return Center(
        child: Text(
          'No resources here',
          style: TextStyle(
            fontSize: 16.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return _ResourceCard(resource: resource);
      },
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Map<String, String> resource;

  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final image = resource['image'];
    final hasImage = image != null && image.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(resource['link'] ?? '')),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              if (hasImage) ...[
                _Thumb(url: image),
                const SizedBox(width: 14.0),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'] ?? '',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      resource['description'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              Icon(
                Icons.open_in_new,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String url;

  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 56,
      height: 56,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Icon(
        Icons.link,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}
