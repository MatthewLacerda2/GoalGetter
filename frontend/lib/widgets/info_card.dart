import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Color? backgroundColor;
  final Color? borderColor;

  const InfoCard({
    super.key,
    this.title,
    this.description,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.24),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          if (title != null && description != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.white),
            const SizedBox(height: 10),
          ],
          if (description != null)
            Text(
              description!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }
}
