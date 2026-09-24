import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';

import 'package:goal_getter/features/lessons/presentation/widgets/stat.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

class FinishLessonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final StatData timeSpent;
  final StatData accuracy;
  final StatData elo;

  FinishLessonScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.timeSpent,
    required this.accuracy,
    required this.elo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: _Summary(
                  title: title,
                  icon: icon,
                  timeSpent: timeSpent,
                  accuracy: accuracy,
                  elo: elo,
                ),
              ),
              const _ContinueButton(),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lesson's result: its name, the trophy, and the three stat tiles.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.title,
    required this.icon,
    required this.timeSpent,
    required this.accuracy,
    required this.elo,
  });

  final String title;
  final IconData icon;
  final StatData timeSpent;
  final StatData accuracy;
  final StatData elo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 24),
        Icon(icon, color: theme.colorScheme.secondary, size: 140),
        SizedBox(height: 60),
        Row(
          children: [
            Expanded(child: StatWidget(statData: timeSpent)),
            SizedBox(width: 12.0),
            Expanded(child: StatWidget(statData: accuracy)),
            SizedBox(width: 12.0),
            Expanded(child: StatWidget(statData: elo)),
          ],
        ),
      ],
    );
  }
}

/// Back to Home — the only way out of the finish screen.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go(AppRoutes.home),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
        child: Text(
          AppLocalizations.of(context).continuate,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: scheme.onPrimary),
        ),
      ),
    );
  }
}
