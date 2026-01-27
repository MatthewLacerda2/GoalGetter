import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.4),
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSize18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: AppTheme.textTertiary.withValues(alpha: 0.33),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.accentPrimary,
            ),
            minHeight: AppTheme.spacing12,
            borderRadius: BorderRadius.circular(AppTheme.spacing12),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}