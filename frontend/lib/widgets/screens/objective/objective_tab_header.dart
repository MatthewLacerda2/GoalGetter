import 'package:flutter/material.dart';
import 'package:goal_getter/screens/objective/streak_screen.dart';

import '../../../../l10n/app_localizations.dart';

class ObjectiveTabHeader extends StatelessWidget {
  final int overallXp;
  final String objectiveTitle;
  final int streakCounter;
  final Color streakBadgeBackgroundColor;

  static const double buttonsHeight = 44;

  const ObjectiveTabHeader({
    super.key,
    required this.overallXp,
    required this.objectiveTitle,
    required this.streakCounter,
    required this.streakBadgeBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBadgeBackground = streakBadgeBackgroundColor.a > 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(bottom: BorderSide(color: Colors.green, width: 4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '$overallXp XP',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              objectiveTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: buttonsHeight,
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
                foregroundColor: Colors.white,
                elevation: hasBadgeBackground ? 2 : 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streakCounter',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
