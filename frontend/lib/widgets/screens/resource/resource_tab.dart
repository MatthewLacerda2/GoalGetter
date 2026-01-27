import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';

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
            fontSize: AppTheme.fontSize18,
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        final hasImage =
            resource['image'] != null && resource['image']!.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                        BorderRadius.circular(AppTheme.cardRadius),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.cardPadding),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppTheme.spacing8),
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
                                    color: AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.spacing8,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: AppTheme.textTertiary,
                                    size: 28,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resource['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    fontSize: AppTheme.fontSize16,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacing4),
                                Text(
                                  resource['description'] ?? '',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: AppTheme.fontSize14,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding,
                      vertical: AppTheme.spacing8,
                    ),
                    subtitle: Text(
                      resource['description'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSize14,
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
