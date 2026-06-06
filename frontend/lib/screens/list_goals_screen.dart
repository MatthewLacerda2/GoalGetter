import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../widgets/error_retry_widget.dart';
import 'goals_detail_screen.dart';

class ListGoalsScreen extends StatefulWidget {
  ListGoalsScreen({super.key});

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.goals),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _errorMessage != null
              ? ErrorRetryWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadGoals,
                )
              : _goals.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noGoalsFound,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: _goals.length,
                        itemBuilder: (context, index) {
                          final goal = _goals[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: 12.0),
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
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 16.0,
                                ),
                                minimumSize: Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8.0),
                                ),
                              ),
                              child: Text(
                                goal.name.isNotEmpty
                                    ? goal.name
                                    : AppLocalizations.of(context)!
                                        .untitledGoal,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
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
