import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourceTab extends StatelessWidget {
  final List<Map<String, String>> resources;

  const ResourceTab({
    super.key,
    required this.resources,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        final hasImage = resource['image'] != null && resource['image']!.isNotEmpty;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          color: Colors.grey[400]!.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: hasImage 
            ? InkWell(
                onTap: () {
                  launchUrl(Uri.parse(resource['link'] ?? ''));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_not_supported, color: Colors.white),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resource['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resource['description'] ?? '',
                              style: TextStyle(color: Colors.white),
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
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                subtitle: Text(resource['description'] ?? '', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  launchUrl(Uri.parse(resource['link'] ?? ''));
                },
              ),
        );
      },
    );
  }
}