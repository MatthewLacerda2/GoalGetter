import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:goal_getter/screens/objective/streak_screen.dart';

import '../../widgets/screens/objective/lesson/stat.dart';
import '../../widgets/screens/objective/lesson/stat_data.dart';

class FinishLessonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final StatData timeSpent;
  final StatData accuracy;
  final StatData combo;

  FinishLessonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.timeSpent,
    required this.accuracy,
    required this.combo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    SizedBox(height: 24),
                    Icon(
                      icon,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 140,
                    ),
                    SizedBox(height: 60),
                    Row(
                      children: [
                        Expanded(child: StatWidget(statData: timeSpent)),
                        SizedBox(width: 12.0),
                        Expanded(child: StatWidget(statData: accuracy)),
                        SizedBox(width: 12.0),
                        Expanded(child: StatWidget(statData: combo)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StreakScreen(
                          descriptionText: AppLocalizations.of(
                            context,
                          )!.keepThePressureOn,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20.0),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.continuate,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}
