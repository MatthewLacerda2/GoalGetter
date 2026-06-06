import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../app/app.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../utils/settings_storage.dart';
import 'onboarding/goal_prompt_screen.dart';

class GoalSelectionScreen extends StatefulWidget {
  GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
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
      // Call /goals endpoint using OpenAPI SDK
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

  Future<void> _selectGoal(GoalListItem goal) async {
    try {
      final accessToken = await _authService.getStoredAccessToken();
      // Set goal as active via API using OpenAPI SDK
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createAuthorized();

      final goalsApi = GoalsApi(apiClient);
      final response = await goalsApi.setActiveGoalApiV1GoalsGoalIdSetActivePut(
        goal.id,
      );

      if (response != null) {
        // Store goal ID from response
        if (response.goalId != null) {
          await SettingsStorage.setCurrentGoalId(response.goalId!);
        }

        // Navigate to main screen
        if (mounted) {
          // Check if user has access token (completed onboarding)
          if (accessToken != null && accessToken.isNotEmpty) {
            // User has completed onboarding, navigate to main screen
            Navigator.of(context).pushReplacementNamed(AppRoutes.home);
          } else {
            // User hasn't completed onboarding, go to goal prompt
            Navigator.of(context).pushReplacementNamed(AppRoutes.goalPrompt);
          }
        }
      } else {
        throw Exception('Failed to set active goal: No response received');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGoal(GoalListItem goal, int index) async {
    // First confirmation dialog
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteGoal),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisGoal,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirm1 != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    // Second confirmation dialog
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.warning),
          content: Text(
            AppLocalizations.of(context)!.deleteGoalWarningDescription,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirm2 != true) {
      return;
    }

    try {
      // Delete goal via API using OpenAPI SDK
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createAuthorized();

      final goalsApi = GoalsApi(apiClient);
      await goalsApi.deleteGoalApiV1GoalsGoalIdDelete(goal.id);

      // Remove goal from list
      setState(() {
        _goals.removeAt(index);
      });

      // If no goals left, navigate to goal prompt screen
      if (_goals.isEmpty && mounted) {
        await SettingsStorage.clearCurrentGoal();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => GoalPromptScreen()),
        );
      } else {
        // Reload goals to refresh the list
        await _loadGoals();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting goal: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectGoal),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            )
          : _errorMessage != null
          ? Center(
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
                    onPressed: _loadGoals,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.noGoalsFound,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => GoalPromptScreen(),
                        ),
                      );
                    },
                    child: Text(AppLocalizations.of(context)!.createFirstGoal),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return Dismissible(
                  key: Key(goal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 24.0),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    await _deleteGoal(goal, index);
                    return false;
                  },
                  child: Card(
                    margin: EdgeInsets.only(bottom: 12.0),
                    color: Colors.transparent,
                    elevation: 0,
                    child: ElevatedButton(
                      onPressed: () => _selectGoal(goal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(16.0),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8.0,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name.isNotEmpty
                                ? goal.name
                                : AppLocalizations.of(context)!.untitledGoal,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                          if (goal.description.isNotEmpty) ...[
                            SizedBox(height: 8.0),
                            Text(
                              goal.description,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => GoalPromptScreen()),
          );
          await _loadGoals();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.createNewGoal),
      ),
    );
  }
}
