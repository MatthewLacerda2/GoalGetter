import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final String title;
  final double progress;
  final double end;
  final Color color;

  const ProgressBar({
    super.key,
    required this.title,
    required this.progress,
    required this.end,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = progress / end;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
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
          const SizedBox(height: 8), // Add spacing between text and bar
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.33),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
            minHeight: 12,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}