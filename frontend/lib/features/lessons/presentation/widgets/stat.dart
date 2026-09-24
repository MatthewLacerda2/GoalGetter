import 'package:flutter/material.dart';

import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

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
        borderRadius: BorderRadius.circular(AppRadius.chip),
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        border: Border.all(color: statData.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              vertical: AppSpacing.xs,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: statData.color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.chip),
                topRight: Radius.circular(AppRadius.chip),
              ),
            ),
            child: Text(
              statData.title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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
