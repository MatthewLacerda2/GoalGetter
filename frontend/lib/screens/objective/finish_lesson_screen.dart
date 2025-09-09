import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import 'package:goal_getter/screens/objective/streak_screen.dart';
import '../../widgets/screens/objective/lesson/stat.dart';
import '../../widgets/screens/objective/lesson/stat_data.dart';

class FinishLessonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final StatData timeSpent;
  final StatData accuracy;
  final StatData combo;

  const FinishLessonScreen({
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
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Icon(
                      icon,
                      color: Colors.orange,
                      size: 140,
                    ),
                    const SizedBox(height: 60),
                    // Three stat widgets
                    Row(
                      children: [
                        Expanded(
                          child: StatWidget(statData: timeSpent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatWidget(statData: accuracy),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatWidget(statData: combo),
                        ),
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
                          streakCount: 365,
                          sunday: false,
                          monday: true,
                          tuesday: true,
                          wednesday: true,
                          thursday: true,
                          descriptionText: AppLocalizations.of(context)!.keepThePressureOn,
                        ),
                      ),
                      (route) => false,
                  );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}