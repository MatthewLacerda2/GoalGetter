import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? description;
  final Color? mainColor;
  final Color? descriptionColor;

  const InfoCard({
    super.key,
    required this.title,
    this.description,
    this.mainColor,
    this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mainColor ?? Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor ?? Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}