import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum InfoCardVariant {
  normal,
  ghost,
}

class InfoCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Color? backgroundColor;
  final InfoCardVariant variant;

  const InfoCard({
    super.key,
    this.title,
    this.description,
    this.backgroundColor,
    this.variant = InfoCardVariant.normal,
  });

  const InfoCard.ghost({
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
            : AppTheme.cardBackground);
    final hasShadow = variant != InfoCardVariant.ghost;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
                color: AppTheme.textPrimary,
              ),
            ),
          if (title != null && description != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            Divider(
              height: 1,
              color: AppTheme.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spacing12),
          ],
          if (description != null)
            Text(
              description!,
              style: theme.bodyMedium?.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: AppTheme.notesHeadingSize * 0.8,
                color: AppTheme.textPrimary,
                height: 1.6,
              ),
            ),
        ],
      ),
    );
  }
}
