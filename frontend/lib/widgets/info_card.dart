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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mainColor ?? Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor ?? Colors.white, width: 2),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: mainColor ?? Colors.white,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: mainColor ?? Colors.white),
            const SizedBox(height: 10),
            Text(
              description!,
              style: TextStyle(
                fontSize: 16,
                color: descriptionColor ?? Colors.grey[300],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}