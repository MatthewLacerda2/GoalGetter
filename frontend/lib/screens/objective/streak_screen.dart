// calendar screen
import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../widgets/screens/objective/streak/weekday_column.dart';

class StreakScreen extends StatefulWidget {
  final String descriptionText;

  const StreakScreen({super.key, required this.descriptionText});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  int _streakCount = 0;
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
      // Get the stored access token
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available. Please sign in again.');
      }

      // Create API client and add the access token as Authorization header
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

      // Fetch student status to get student_id if not already fetched
      if (_studentId == null) {
        final studentApi = StudentApi(apiClient);
        final studentResponse = await studentApi
            .getStudentCurrentStatusApiV1StudentGet();

        if (studentResponse == null) {
          throw Exception('Failed to fetch student status');
        }

        _studentId = studentResponse.studentId;
      }

      // Fetch week streak data
      final streakApi = StreakApi(apiClient);
      final streakResponse = await streakApi
          .getWeekStreakApiV1StreakStudentIdWeekGet(_studentId!);

      if (mounted && streakResponse != null) {
        setState(() {
          _streakCount = streakResponse.currentStreak;

          // Parse streak days to determine weekday completion
          final streakDays = streakResponse.streakDays;
          final completedDays = <int>{};

          for (final streakDay in streakDays) {
            // DateTime.weekday returns 1-7 (Monday=1, Sunday=7)
            completedDays.add(streakDay.dateTime.weekday);
          }

          // Get today's date (normalized to start of day for comparison)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final todayWeekday = today.weekday;

          // Calculate start of current week (Monday)
          // DateTime.weekday returns 1-7 (Monday=1, Sunday=7)
          final daysFromMonday = todayWeekday - 1;
          final startOfWeek = today.subtract(Duration(days: daysFromMonday));

          // Helper function to determine if a weekday has passed
          // Only set to true/false if the day has passed (or is today), otherwise null (grey for future days)
          bool? getWeekdayStatus(int weekday) {
            // Calculate the date for this weekday in the current week
            // weekday: 1=Monday, 2=Tuesday, ..., 7=Sunday
            final dayDate = startOfWeek.add(Duration(days: weekday - 1));

            // Check if this day has passed (is before or equal to today)
            if (dayDate.isBefore(today) || dayDate.isAtSameMomentAs(today)) {
              // Day has passed (or is today) - show true if completed, false if not
              return completedDays.contains(weekday);
            } else {
              // Day hasn't passed yet - show as null (grey)
              return null;
            }
          }

          // Map weekdays: 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday, 7=Sunday
          _monday = getWeekdayStatus(1);
          _tuesday = getWeekdayStatus(2);
          _wednesday = getWeekdayStatus(3);
          _thursday = getWeekdayStatus(4);
          _friday = getWeekdayStatus(5);
          _saturday = getWeekdayStatus(6);
          _sunday = getWeekdayStatus(7);

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to fetch streak data';
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
        backgroundColor: Colors.grey[900],
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchWeekStreak,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                          '$_streakCount',
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
                      style: TextStyle(color: Colors.white, fontSize: 26),
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
                            const SizedBox(height: 20),
                            const Divider(color: Colors.grey, thickness: 1),
                            const SizedBox(height: 12),
                            Text(
                              widget.descriptionText,
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
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(
                          title: 'GoalGetter',
                          onLanguageChanged: (language) {},
                        ),
                      ),
                      (route) => false,
                    );
                  },
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
