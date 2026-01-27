import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../theme/app_theme.dart';
import 'goals_detail_screen.dart';

class ListGoalsScreen extends StatefulWidget {
  const ListGoalsScreen({super.key});

  @override
  State<ListGoalsScreen> createState() => _ListGoalsScreenState();
}

class _ListGoalsScreenState extends State<ListGoalsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<GoalListItem> _goals = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createAuthorized();

      final goalsApi = GoalsApi(apiClient);
      final goalsResponse = await goalsApi.listGoalsApiV1GoalsGet();

      setState(() {
        _goals = goalsResponse?.goals ?? [];
        _isLoading = false;
      });

      if (goalsResponse == null) {
        throw Exception('Failed to load goals: No response received');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.goals),
        backgroundColor: AppTheme.surfaceVariant,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
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
                        onPressed: _loadGoals,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _goals.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noGoalsFound,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSize18,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppTheme.edgePadding),
                      child: ListView.builder(
                        itemCount: _goals.length,
                        itemBuilder: (context, index) {
                          final goal = _goals[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spacing12),
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.of(context)
                                    .push<GoalsDetailResult>(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            GoalsDetailScreen(goal: goal),
                                      ),
                                    );

                                if (result == GoalsDetailResult.deleted) {
                                  await _loadGoals();
                                }

                                if (result == GoalsDetailResult.activated) {
                                  if (!context.mounted) {
                                    return;
                                  }
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: AppTheme.spacing16,
                                ),
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.spacing8),
                                ),
                              ),
                              child: Text(
                                goal.name.isNotEmpty
                                    ? goal.name
                                    : AppLocalizations.of(context)!
                                        .untitledGoal,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: AppTheme.fontSize16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
