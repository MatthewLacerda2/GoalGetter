import 'package:flutter/material.dart';
import 'package:goal_getter/screens/objective/streak_screen.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';

class ObjectiveTabHeader extends StatelessWidget {
  final int overallXp;
  final String goalTitle;
  final String objectiveTitle;
  final int streakCounter;
  final Color streakBadgeBackgroundColor;

  static const double _buttonsHeight = 44;

  const ObjectiveTabHeader({
    super.key,
    required this.overallXp,
    required this.goalTitle,
    required this.objectiveTitle,
    required this.streakCounter,
    required this.streakBadgeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasBadgeBackground = streakBadgeBackgroundColor.a > 0;
    
    // Determine the content colors for readability and contrast
    final Color contentColor;
    if (hasBadgeBackground) {
      if (streakBadgeBackgroundColor == AppTheme.accentSecondary) {
        contentColor = AppTheme.background;
      } else {
        contentColor = AppTheme.textPrimary;
      }
    } else {
      contentColor = AppTheme.textPrimary;
    }

    final Color iconColor = hasBadgeBackground
        ? contentColor
        : AppTheme.accentSecondary;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.accentPrimary,
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '$overallXp XP',
            style: const TextStyle(
              fontSize: AppTheme.fontSize18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentPrimary,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (goalTitle.isNotEmpty)
                  Text(
                    goalTitle,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (goalTitle.isNotEmpty) const SizedBox(height: 2),
                Text(
                  objectiveTitle.isNotEmpty ? objectiveTitle : 'No Active Objective',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          SizedBox(
            height: _buttonsHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StreakScreen(
                      descriptionText: AppLocalizations.of(
                        context,
                      )!.keepThePressureOn,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: hasBadgeBackground
                    ? streakBadgeBackgroundColor
                    : AppTheme.cardBackground,
                foregroundColor: contentColor,
                elevation: hasBadgeBackground ? AppTheme.cardElevation : 0,
                side: hasBadgeBackground
                    ? BorderSide.none
                    : BorderSide(
                        color: AppTheme.textTertiary.withOpacity(0.5),
                        width: 1,
                      ),
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: AppTheme.spacing8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.spacing8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    '$streakCounter',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: FontWeight.bold,
                      color: contentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
