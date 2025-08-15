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
          shadowColor: Colors.grey[400],
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
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
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
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resource['description'] ?? '',
                              style: TextStyle(color: Colors.grey[400]),
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
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(resource['description'] ?? ''),
                onTap: () {
                  launchUrl(Uri.parse(resource['link'] ?? ''));
                },
              ),
        );
      },
    );
  }
}