// calendar screen
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/screens/objective/streak/weekday_column.dart';

class StreakScreen extends StatelessWidget {
  final int streakCount;
  final bool sunday;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final String descriptionText;

  const StreakScreen({
    super.key,
    required this.streakCount,
    required this.sunday,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.descriptionText,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 80,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$streakCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      AppLocalizations.of(context)!.dayStreak,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Card(
                      color: Colors.grey[800],
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(context)!.sundayShort,
                                  isCompleted: sunday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(context)!.mondayShort,
                                  isCompleted: monday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(context)!.tuesdayShort,
                                  isCompleted: tuesday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(context)!.wednesdayShort,
                                  isCompleted: wednesday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(context)!.thursdayShort,
                                  isCompleted: thursday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(context)!.fridayShort,
                                  isCompleted: friday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(context)!.saturdayShort,
                                  isCompleted: saturday,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.grey, thickness: 1),
                            const SizedBox(height: 14),
                            Text(
                              descriptionText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}