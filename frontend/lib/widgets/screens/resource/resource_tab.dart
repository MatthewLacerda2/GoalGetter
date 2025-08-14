import 'package:flutter/material.dart';

class ResourceTab extends StatelessWidget {
  final List<Map<String, String>> resources;

  const ResourceTab({
    super.key,
    required this.resources,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            title: Text(
              resource['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(resource['description'] ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Handle resource tap
            },
          ),
        );
      },
    );
  }
}