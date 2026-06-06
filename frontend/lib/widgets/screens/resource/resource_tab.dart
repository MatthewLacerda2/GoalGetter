import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceTab extends StatelessWidget {
  final List<Map<String, String>> resources;

  ResourceTab({super.key, required this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return Center(
        child: Text(
          'No resources here',
          style: TextStyle(
            fontSize: 18.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12.0),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        final hasImage =
            resource['image'] != null && resource['image']!.isNotEmpty;

        return Container(
          margin: EdgeInsets.only(bottom: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: hasImage
                ? InkWell(
                    onTap: () {
                      launchUrl(Uri.parse(resource['link'] ?? ''));
                    },
                    borderRadius:
                        BorderRadius.circular(20.0),
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(8.0),
                            child: Image.network(
                              resource['image']!,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                      8.0,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Theme.of(context).colorScheme.outline,
                                    size: 28,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resource['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16.0,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  resource['description'] ?? '',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListTile(
                    title: Text(
                      resource['title'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    subtitle: Text(
                      resource['description'] ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14.0,
                      ),
                    ),
                    onTap: () {
                      launchUrl(Uri.parse(resource['link'] ?? ''));
                    },
                  ),
          ),
        );
      },
    );
  }
}
