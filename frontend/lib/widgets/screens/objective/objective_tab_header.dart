import 'package:flutter/material.dart';
import 'package:goal_getter/screens/objective/streak_screen.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';

class ObjectiveTabHeader extends StatelessWidget {
  final int overallXp;
  final String objectiveTitle;
  final int streakCounter;
  final Color streakBadgeBackgroundColor;

  static const double _buttonsHeight = 44;

  const ObjectiveTabHeader({
    super.key,
    required this.overallXp,
    required this.objectiveTitle,
    required this.streakCounter,
    required this.streakBadgeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasBadgeBackground = streakBadgeBackgroundColor.a > 0;
    return Container(
      decoration: BoxDecoration(
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
            child: Text(
              objectiveTitle,
              style: const TextStyle(
                fontSize: AppTheme.fontSize20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                backgroundColor: hasBadgeBackground
                    ? streakBadgeBackgroundColor
                    : Colors.transparent,
                foregroundColor: hasBadgeBackground
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                elevation: hasBadgeBackground ? AppTheme.cardElevation : 0,
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
                    color: hasBadgeBackground
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    '$streakCounter',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: FontWeight.bold,
                      color: hasBadgeBackground
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
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
