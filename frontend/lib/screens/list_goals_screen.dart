import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/settings_storage.dart';

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
      final accessToken = await _authService.getStoredAccessToken();
      final googleToken = await _authService.getStoredGoogleToken();
      final authToken = accessToken ?? googleToken;

      if (authToken == null) {
        throw Exception('No authentication token available');
      }

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

  Future<void> _setActiveGoal(GoalListItem goal) async {
    try {
      final accessToken = await _authService.getStoredAccessToken();
      final googleToken = await _authService.getStoredGoogleToken();
      final authToken = accessToken ?? googleToken;

      if (authToken == null) {
        throw Exception('No authentication token available');
      }

      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $authToken');

      final goalsApi = GoalsApi(apiClient);
      final response = await goalsApi.setActiveGoalApiV1GoalsGoalIdSetActivePut(
        goal.id,
      );

      if (response != null) {
        if (response.goalId != null) {
          await SettingsStorage.setCurrentGoalId(response.goalId!);
        }

        if (accessToken != null) {
          try {
            final objectiveApi = ObjectiveApi(apiClient);
            final objectiveResponse = await objectiveApi
                .getObjectiveApiV1ObjectiveGet();

            if (objectiveResponse != null) {
              await SettingsStorage.setCurrentObjectiveId(objectiveResponse.id);
            }
          } catch (e) {
            // If we can't fetch objective ID, continue anyway
          }
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Failed to set active goal: No response received');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting active goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
          ? const Center(
              child: Text(
                'No goals found',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () => _setActiveGoal(goal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        goal.name.isNotEmpty ? goal.name : 'Untitled Goal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
