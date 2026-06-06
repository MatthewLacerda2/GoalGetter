import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/services/openapi_client_factory.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/weekday_column.dart';
import 'package:goal_getter/features/lessons/debug/mock_streak_screen.dart';

class StreakScreen extends StatefulWidget {
  final String descriptionText;

  StreakScreen({super.key, required this.descriptionText});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  int _streakCount = 0;
  Color _streakIconBackgroundColor = Colors.transparent;
  String? _studentId;
  bool? _sunday;
  bool? _monday;
  bool? _tuesday;
  bool? _wednesday;
  bool? _thursday;
  bool? _friday;
  bool? _saturday;

  @override
  void initState() {
    super.initState();
    _fetchWeekStreak();
  }

  Future<void> _fetchWeekStreak() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mockData = await getMockStreakData();
      if (mounted) {
        setState(() {
          _streakCount = mockData.currentStreak;
          _monday = mockData.monday;
          _tuesday = mockData.tuesday;
          _wednesday = mockData.wednesday;
          _thursday = mockData.thursday;
          _friday = mockData.friday;
          _saturday = mockData.saturday;
          _sunday = mockData.sunday;
          
          // Color coding for fire streak icon
          if (mockData.friday == true) {
            _streakIconBackgroundColor = Theme.of(context).colorScheme.secondary;
          } else {
            _streakIconBackgroundColor = Colors.transparent;
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: $_errorMessage',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _fetchWeekStreak,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _streakIconBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(
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
                              SizedBox(width: 8.0),
                              Text(
                                '$_streakCount',
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
                    SizedBox(height: 36),
                    Card(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(
                                    context,
                                  )!.sundayShort,
                                  isCompleted: _sunday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(
                                    context,
                                  )!.mondayShort,
                                  isCompleted: _monday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(
                                    context,
                                  )!.tuesdayShort,
                                  isCompleted: _tuesday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(
                                    context,
                                  )!.wednesdayShort,
                                  isCompleted: _wednesday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(
                                    context,
                                  )!.thursdayShort,
                                  isCompleted: _thursday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(
                                    context,
                                  )!.fridayShort,
                                  isCompleted: _friday,
                                ),
                                WeekdayColumn(
                                  dayLabel: AppLocalizations.of(
                                    context,
                                  )!.saturdayShort,
                                  isCompleted: _saturday,
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Divider(
                              color: Theme.of(context).colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                              thickness: 1,
                            ),
                            SizedBox(height: 12.0),
                            Text(
                              widget.descriptionText,
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
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20.0,
                      ),
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
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
