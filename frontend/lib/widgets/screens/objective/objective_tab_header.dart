import 'package:flutter/material.dart';
import 'package:goal_getter/screens/objective/streak_screen.dart';

import '../../../../l10n/app_localizations.dart';

class ObjectiveTabHeader extends StatelessWidget {
  final int overallXp;
  final String objectiveTitle;
  final int streakCounter;

  static const double buttonsHeight = 44;

  const ObjectiveTabHeader({
    super.key,
    required this.overallXp,
    required this.objectiveTitle,
    required this.streakCounter,
  });

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: Colors
                    .orange, //TODO: make this go cyanGrey if the user didnt finish a lesson today
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$streakCounter',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
