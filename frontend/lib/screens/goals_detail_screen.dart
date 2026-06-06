import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../utils/settings_storage.dart';

enum GoalsDetailResult { deleted, activated }

class GoalsDetailScreen extends StatefulWidget {
  GoalsDetailScreen({super.key, required this.goal});

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
          backgroundColor: Theme.of(context).colorScheme.error,
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
        await SettingsStorage.clearCurrentGoal();
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
          backgroundColor: Theme.of(context).colorScheme.error,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(goalTitle),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goalTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12.0),
              Text(
                widget.goal.description.isNotEmpty
                    ? widget.goal.description
                    : AppLocalizations.of(context)!.noDescription,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 12.0),
              Text(
                _formatCreatedAt(context, widget.goal.createdAt),
                style: TextStyle(
                  fontSize: 14.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isDeleting || _isSettingActive)
                      ? null
                      : _setAsCurrentGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          20.0),
                    ),
                    elevation: 0,
                  ),
                  child: _isSettingActive
                      ? SizedBox(
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
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isDeleting || _isSettingActive)
                      ? null
                      : _deleteGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          20.0),
                    ),
                    elevation: 0,
                  ),
                  child: _isDeleting
                      ? SizedBox(
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
                            fontSize: 16.0,
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
