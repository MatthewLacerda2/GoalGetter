import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../utils/settings_storage.dart';

enum GoalsDetailResult { deleted, activated }

class GoalsDetailScreen extends StatefulWidget {
  const GoalsDetailScreen({super.key, required this.goal});

  final GoalListItem goal;

  @override
  State<GoalsDetailScreen> createState() => _GoalsDetailScreenState();
}

class _GoalsDetailScreenState extends State<GoalsDetailScreen> {
  final AuthService _authService = AuthService();
  bool _isDeleting = false;
  bool _isSettingActive = false;

  String _formatCreatedAt(BuildContext context, DateTime createdAt) {
    try {
      return DateFormat.yMMMd().add_jm().format(createdAt.toLocal());
    } catch (_) {
      return createdAt.toLocal().toIso8601String();
    }
  }

  Future<void> _setAsCurrentGoal() async {
    setState(() {
      _isSettingActive = true;
    });

    try {
      final accessToken = await _authService.getStoredAccessToken();
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createAuthorized();

      final goalsApi = GoalsApi(apiClient);
      final response = await goalsApi.setActiveGoalApiV1GoalsGoalIdSetActivePut(
        widget.goal.id,
      );

      if (response == null || response.goalId == null) {
        throw Exception('Failed to set active goal: No response received');
      }

      await SettingsStorage.setCurrentGoalId(response.goalId!);

      // Only try to fetch objective if we have a JWT access token (same as prior behavior).
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final objectiveApi = ObjectiveApi(apiClient);
          final objectiveResponse = await objectiveApi
              .getObjectiveApiV1ObjectiveGet();

          if (objectiveResponse != null) {
            await SettingsStorage.setCurrentObjectiveId(objectiveResponse.id);
          }
        } catch (_) {
          // If we can't fetch objective ID, continue anyway.
        }
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(GoalsDetailResult.activated);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSettingActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting active goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
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

    if (confirm != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createAuthorized();

      final goalsApi = GoalsApi(apiClient);
      await goalsApi.deleteGoalApiV1GoalsGoalIdDelete(widget.goal.id);

      final currentGoalId = await SettingsStorage.getCurrentGoalId();
      if (currentGoalId == widget.goal.id) {
        await SettingsStorage.clearCurrentGoalAndObjective();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(GoalsDetailResult.deleted);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalTitle = widget.goal.name.isNotEmpty
        ? widget.goal.name
        : AppLocalizations.of(context)!.untitledGoal;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(goalTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goalTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.goal.description.isNotEmpty
                    ? widget.goal.description
                    : AppLocalizations.of(context)!.noDescription,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatCreatedAt(context, widget.goal.createdAt),
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isDeleting || _isSettingActive)
                      ? null
                      : _setAsCurrentGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSettingActive
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.setAsCurrentGoal,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isDeleting || _isSettingActive)
                      ? null
                      : _deleteGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context)!.deleteGoal,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
