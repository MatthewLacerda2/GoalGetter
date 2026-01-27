import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import 'stat_data.dart';

class StatWidget extends StatelessWidget {
  final StatData statData;

  const StatWidget({
    super.key,
    required this.statData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        color: AppTheme.textTertiary.withValues(alpha: 0.12),
        border: Border.all(color: statData.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacing8,
              horizontal: AppTheme.spacing12,
            ),
            decoration: BoxDecoration(
              color: statData.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.cardRadius),
                topRight: Radius.circular(AppTheme.cardRadius),
              ),
            ),
            child: Text(
              statData.title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppTheme.fontSize14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statData.icon,
                  color: statData.color,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  statData.text,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSize16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}