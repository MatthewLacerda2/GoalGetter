import 'package:flutter/material.dart';
import 'package:goal_getter/screens/objective/streak_screen.dart';
import '../../../../l10n/app_localizations.dart';

class ObjectiveTabHeader extends StatelessWidget {
  
  final String goalTitle;
  final int streakCounter;

  static const double buttonsHeight = 44;

  const ObjectiveTabHeader({
    super.key,
    required this.goalTitle,
    required this.streakCounter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        border: Border(
          bottom: BorderSide(
            color: Colors.green,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: SizedBox(
              height: buttonsHeight,
              child: Center(
                child: Text(
                  goalTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          SizedBox(
            height: buttonsHeight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StreakScreen(
                      streakCount: streakCounter,
                      sunday: false,
                      monday: true,
                      tuesday: true,
                      wednesday: true,
                      thursday: true,
                      descriptionText: AppLocalizations.of(context)!.keepThePressureOn,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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