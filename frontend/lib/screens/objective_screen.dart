import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import 'package:openapi/api.dart';

import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../theme/app_theme.dart';
import '../widgets/info_card.dart';
import '../widgets/screens/objective/lesson_button.dart';
import '../widgets/screens/objective/objective_tab_header.dart';

class ObjectiveScreen extends StatefulWidget {
  const ObjectiveScreen({super.key});

  @override
  State<ObjectiveScreen> createState() => _ObjectiveScreenState();
}

class _ObjectiveScreenState extends State<ObjectiveScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;

  int? _overallXp;
  int? _streakCounter;
  Color _streakBadgeBackgroundColor = Colors.transparent;
  String? _objectiveName;
  List<ObjectiveNote>? _notes;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createWithAccessToken();

      // Fetch student status and objective in parallel
      final studentApi = StudentApi(apiClient);
      final objectiveApi = ObjectiveApi(apiClient);
      final streakApi = StreakApi(apiClient);

      final studentResponse = await studentApi
          .getStudentCurrentStatusApiV1StudentGet();
      final objectiveResponse = await objectiveApi
          .getObjectiveApiV1ObjectiveGet();

      if (studentResponse == null) {
        throw Exception('Failed to fetch student status');
      }

      if (objectiveResponse == null) {
        throw Exception('Failed to fetch objective');
      }

      // Fetch week streak data (used only to decide streak badge background in header).
      // The streak counter continues to come from `studentResponse.currentStreak`.
      final streakResponse = await streakApi
          .getWeekStreakApiV1StreakStudentIdWeekGet(studentResponse.studentId);

      Color computeStreakBadgeBackgroundColor() {
        final streakDays = streakResponse?.streakDays ?? <StreakDayResponse>[];

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBeforeYesterday = today.subtract(const Duration(days: 2));

        bool hasDay(DateTime targetDay) {
          for (final streakDay in streakDays) {
            final dt = streakDay.dateTime.toLocal();
            final normalized = DateTime(dt.year, dt.month, dt.day);
            if (normalized == targetDay) return true;
          }
          return false;
        }

        if (hasDay(today)) return AppTheme.accentSecondary;
        if (hasDay(yesterday) || hasDay(dayBeforeYesterday)) {
          return AppTheme.textTertiary;
        }
        return Colors.transparent;
      }

      if (mounted) {
        setState(() {
          _overallXp = studentResponse.overallXp;
          _streakCounter = studentResponse.currentStreak;
          _streakBadgeBackgroundColor = computeStreakBadgeBackgroundColor();
          _objectiveName = objectiveResponse.name;
          _notes = objectiveResponse.notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          ObjectiveTabHeader(
            overallXp: _overallXp ?? 0,
            objectiveTitle: _objectiveName ?? '',
            streakCounter: _streakCounter ?? 0,
            streakBadgeBackgroundColor: _streakBadgeBackgroundColor,
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentPrimary,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: $_errorMessage',
                              style: const TextStyle(color: AppTheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            ElevatedButton(
                              onPressed: _fetchData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(AppTheme.spacing12),
                        children: [
                          const SizedBox(height: AppTheme.spacing12),
                          if (_objectiveName != null)
                            LessonButton(
                              label: AppLocalizations.of(context)!
                                  .startLesson,
                            ),
                          if (_notes != null && _notes!.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacing12),
                            Text(
                              '${AppLocalizations.of(context)!.notes}:',
                              style: const TextStyle(
                                fontSize: AppTheme.notesHeadingSize,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            ..._notes!.map(
                              (note) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppTheme.spacing16),
                                child: InfoCard(
                                  description: note.info,
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppTheme.spacing24),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
