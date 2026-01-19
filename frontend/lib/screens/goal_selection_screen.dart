import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../config/app_config.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../utils/settings_storage.dart';
import 'onboarding/goal_prompt_screen.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

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
      // Get access token or Google token
      final accessToken = await _authService.getStoredAccessToken();
      final googleToken = await _authService.getStoredGoogleToken();
      final authToken = accessToken ?? googleToken;

      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      // Call /goals endpoint using OpenAPI SDK
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $authToken');

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
      // Get access token or Google token
      final accessToken = await _authService.getStoredAccessToken();
      final googleToken = await _authService.getStoredGoogleToken();
      final authToken = accessToken ?? googleToken;

      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      // Set goal as active via API using OpenAPI SDK
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $authToken');

      final goalsApi = GoalsApi(apiClient);
      final response = await goalsApi.setActiveGoalApiV1GoalsGoalIdSetActivePut(
        goal.id,
      );

      if (response != null) {
        // Store goal ID from response
        if (response.goalId != null) {
          await SettingsStorage.setCurrentGoalId(response.goalId!);
        }

        // Fetch objective ID from objective endpoint
        if (accessToken != null) {
          try {
            final objectiveApi = ObjectiveApi(apiClient);
            final objectiveResponse = await objectiveApi
                .getObjectiveApiV1ObjectiveGet();

            if (objectiveResponse != null) {
              await SettingsStorage.setCurrentObjectiveId(objectiveResponse.id);
            }
          } catch (e) {
            // If we can't fetch objective ID, continue anyway - main screen will handle it
          }
        }

        // Navigate to main screen
        if (mounted) {
          // Check if user has access token (completed onboarding)
          if (accessToken != null && accessToken.isNotEmpty) {
            // User has completed onboarding, navigate to main screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MyHomePage(
                  title: 'Goal Getter',
                  onLanguageChanged: (String) {},
                ),
              ),
            );
          } else {
            // User hasn't completed onboarding, go to goal prompt
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const GoalPromptScreen()),
            );
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
          title: const Text('Delete Goal?'),
          content: const Text(
            'Are you sure you want to delete this goal? This action cannot be reversed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm1 != true) {
      return;
    }

    // Second confirmation dialog
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Warning'),
          content: const Text(
            'Warning: This will permanently delete the goal and all its objectives. This action cannot be reversed. Are you absolutely sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm2 != true) {
      return;
    }

    try {
      // Get access token or Google token
      final accessToken = await _authService.getStoredAccessToken();
      final googleToken = await _authService.getStoredGoogleToken();
      final authToken = accessToken ?? googleToken;

      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      // Delete goal via API using OpenAPI SDK
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $authToken');

      final goalsApi = GoalsApi(apiClient);
      await goalsApi.deleteGoalApiV1GoalsGoalIdDelete(goal.id);

      // Remove goal from list
      setState(() {
        _goals.removeAt(index);
      });

      // If no goals left, navigate to goal prompt screen
      if (_goals.isEmpty && mounted) {
        await SettingsStorage.clearCurrentGoalAndObjective();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GoalPromptScreen()),
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Select Goal'),
        backgroundColor: Colors.grey[800],
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGoals,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No goals found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const GoalPromptScreen(),
                        ),
                      );
                    },
                    child: const Text('Create First Goal'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _goals.length,
              itemBuilder: (context, index) {
                final goal = _goals[index];
                return Dismissible(
                  key: Key(goal.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    // Show confirmation dialogs
                    await _deleteGoal(goal, index);
                    return false; // We handle deletion manually
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.transparent,
                    elevation: 0,
                    child: ElevatedButton(
                      onPressed: () => _selectGoal(goal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.name.isNotEmpty ? goal.name : 'Untitled Goal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (goal.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              goal.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
          // Navigate to goal prompt screen
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const GoalPromptScreen()),
          );
          // Reload goals when returning from goal prompt
          await _loadGoals();
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Create New Goal'),
      ),
    );
  }
}
