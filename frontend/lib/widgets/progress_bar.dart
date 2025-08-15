import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double progress;
  final double end;
  final Color color;

  const ProgressBar({
    super.key,
    required this.title,
    this.icon,
    required this.progress,
    required this.end,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = progress / end;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.33),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 16,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}