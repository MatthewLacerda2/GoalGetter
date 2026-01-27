import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class PlayerBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final double fontSize;
  final Color? iconColor;
  final Color? textColor;

  const PlayerBadge({
    super.key,
    required this.icon,
    required this.text,
    this.fontSize = 12,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: AppTheme.textTertiary.withValues(alpha: 0.5),
          width: 2.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: iconColor ?? AppTheme.accentPrimary,
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
