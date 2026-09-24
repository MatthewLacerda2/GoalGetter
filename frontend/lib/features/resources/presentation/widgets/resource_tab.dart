import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:goal_getter/features/resources/domain/resource_item.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// A tab of curated resources. Each item is a clean white card with an optional
/// thumbnail/logo, a title + description, and a trailing open-in-new link icon
/// (to read as clickable). Tapping opens the link.
class ResourceTab extends StatelessWidget {
  final List<ResourceItem> resources;

  const ResourceTab({super.key, required this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noResourcesOfThisKind,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return _ResourceCard(resource: resource);
      },
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final ResourceItem resource;

  const _ResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final image = resource.imageUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(resource.url)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              if (image != null && image.isNotEmpty) ...[
                _Thumb(url: image),
                const SizedBox(width: 14.0),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      resource.description,
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
      borderRadius: BorderRadius.circular(AppRadius.control),
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
