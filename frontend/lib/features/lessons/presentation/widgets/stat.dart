import 'package:flutter/material.dart';

import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';

class StatWidget extends StatelessWidget {
  final StatData statData;

  StatWidget({
    super.key,
    required this.statData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        border: Border.all(color: statData.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              color: statData.color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Text(
              statData.title.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statData.icon,
                  color: statData.color,
                  size: 24,
                ),
                SizedBox(width: 12.0),
                Text(
                  statData.text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16.0,
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
