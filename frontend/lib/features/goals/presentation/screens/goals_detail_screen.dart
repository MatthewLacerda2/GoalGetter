import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';

enum GoalsDetailResult { deleted, activated }

class GoalsDetailScreen extends StatefulWidget {
  const GoalsDetailScreen({super.key, required this.goal});

  final Goal goal;

  @override
  State<GoalsDetailScreen> createState() => _GoalsDetailScreenState();
}

class _GoalsDetailScreenState extends State<GoalsDetailScreen> {
  bool _isDeleting = false;
  bool _isSettingActive = false;

  String _formatCreatedAt(DateTime createdAt) {
    try {
      return DateFormat.yMMMd().format(createdAt.toLocal());
    } catch (_) {
      return createdAt.toLocal().toIso8601String();
    }
  }

  // MOCK: no backend yet — simulate setting the active goal.
  Future<void> _setAsCurrentGoal() async {
    setState(() => _isSettingActive = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.pop(GoalsDetailResult.activated);
  }

  // MOCK: no backend yet — simulate deleting the goal.
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

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.pop(GoalsDetailResult.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final goalTitle = widget.goal.name.isNotEmpty
        ? widget.goal.name
        : AppLocalizations.of(context)!.untitledGoal;
    final successColor =
        Theme.of(context).extension<CustomColors>()?.success ?? Colors.green;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(goalTitle),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goalTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (widget.goal.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: successColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                '${AppLocalizations.of(context)!.elo} ${widget.goal.currentElo}',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12.0),
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
              const SizedBox(height: 12.0),
              Text(
                _formatCreatedAt(widget.goal.createdAt),
                style: TextStyle(
                  fontSize: 14.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isDeleting || _isSettingActive || widget.goal.isActive)
                      ? null
                      : _setAsCurrentGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
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
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isDeleting || _isSettingActive)
                      ? null
                      : _deleteGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
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
                          style: const TextStyle(
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
