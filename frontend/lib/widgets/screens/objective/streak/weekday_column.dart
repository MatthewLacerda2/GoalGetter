import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';

class WeekdayColumn extends StatelessWidget {
  final String dayLabel;
  final bool? isCompleted;
  final double width;

  const WeekdayColumn({
    super.key,
    required this.dayLabel,
    required this.isCompleted,
    this.width = 42,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final IconData circleIcon;
    if (isCompleted == null) {
      circleColor = AppTheme.textTertiary;
      circleIcon = Icons.remove;
    } else if (isCompleted == true) {
      circleColor = AppTheme.success;
      circleIcon = Icons.check;
    } else {
      circleColor = AppTheme.error;
      circleIcon = Icons.close;
    }

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: AppTheme.fontSize16,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
            ),
            child: Icon(
              circleIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

