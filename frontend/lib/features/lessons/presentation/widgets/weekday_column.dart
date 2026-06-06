import 'package:flutter/material.dart';

import 'package:goal_getter/app/theme/app_theme.dart';

class WeekdayColumn extends StatelessWidget {
  final String dayLabel;
  final bool? isCompleted;
  final double width;

  WeekdayColumn({
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
      circleColor = Theme.of(context).colorScheme.outline;
      circleIcon = Icons.remove;
    } else if (isCompleted == true) {
      circleColor = Theme.of(context).extension<CustomColors>()!.success;
      circleIcon = Icons.check;
    } else {
      circleColor = Theme.of(context).colorScheme.error;
      circleIcon = Icons.close;
    }

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          SizedBox(height: 16.0),
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

