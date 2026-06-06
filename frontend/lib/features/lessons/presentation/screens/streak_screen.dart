import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/weekday_column.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/streak_controller.dart';

class StreakScreen extends ConsumerWidget {
  final String descriptionText;

  const StreakScreen({super.key, required this.descriptionText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: $err',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () => ref.refresh(streakProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (mockData) {
        final streakCount = mockData.currentStreak;
        final sunday = mockData.sunday;
        final monday = mockData.monday;
        final tuesday = mockData.tuesday;
        final wednesday = mockData.wednesday;
        final thursday = mockData.thursday;
        final friday = mockData.friday;
        final saturday = mockData.saturday;

        final streakIconBackgroundColor = friday == true
            ? Theme.of(context).colorScheme.secondary
            : Colors.transparent;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: streakIconBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 80,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    '$streakCount',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 80,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppLocalizations.of(context)!.dayStreak,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                Divider(
                                  color: Theme.of(context).colorScheme.outline.withValues(
                                    alpha: 0.5,
                                  ),
                                  thickness: 1,
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  descriptionText,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
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
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.continuate,
                        style: const TextStyle(
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
      },
    );
  }
}
