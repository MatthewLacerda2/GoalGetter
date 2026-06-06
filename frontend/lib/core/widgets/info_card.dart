import 'package:flutter/material.dart';

import 'package:goal_getter/app/theme/app_theme.dart';

enum InfoCardVariant {
  normal,
  ghost,
}

class InfoCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Color? backgroundColor;
  final InfoCardVariant variant;

  InfoCard({
    super.key,
    this.title,
    this.description,
    this.backgroundColor,
    this.variant = InfoCardVariant.normal,
  });

  InfoCard.ghost({
    super.key,
    this.title,
    this.description,
    this.backgroundColor,
  }) : variant = InfoCardVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final effectiveBackgroundColor = backgroundColor ??
        (variant == InfoCardVariant.ghost
            ? Colors.transparent
            : Theme.of(context).colorScheme.surfaceContainer);
    final hasShadow = variant != InfoCardVariant.ghost;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: theme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          if (title != null && description != null) ...[
            SizedBox(height: 12.0),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: 12.0),
          ],
          if (description != null)
            Text(
              description!,
              style: theme.bodyMedium?.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: (theme.bodyMedium?.fontSize ?? 14.0) * 0.9,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }
}
