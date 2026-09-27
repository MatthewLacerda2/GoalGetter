import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';

import 'package:goal_getter/core/theme/app_theme.dart';
import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:goal_getter/core/widgets/lesson_clock.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';

/// The end of a lesson: the server's evaluation of its first round, as three
/// tiles. The route hands over the [evaluation] itself (#222); how each number
/// reads — its words, icon and colour — is decided here.
class FinishLessonScreen extends StatelessWidget {
  final LessonEvaluation evaluation;

  const FinishLessonScreen({super.key, required this.evaluation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(child: _Summary(evaluation: evaluation)),
              const _ContinueButton(),
              SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lesson's result: its title, the trophy, and the three stat tiles.
class _Summary extends StatelessWidget {
  const _Summary({required this.evaluation});

  final LessonEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final elo = evaluation.elo;
    final timeSpent = StatData(
      title: l10n.lessonTime,
      icon: Icons.timer,
      text: formatLessonClock(Duration(seconds: evaluation.totalSecondsSpent)),
      color: theme.colorScheme.primary,
    );
    final accuracy = StatData(
      title: l10n.lessonAccuracy,
      icon: Icons.check_circle,
      text: '${evaluation.studentAccuracy.toStringAsFixed(0)}%',
      color: CustomColors.of(context).success,
    );
    final eloStat = StatData(
      title: l10n.elo,
      icon: Icons.trending_up,
      text: elo >= 0 ? '+$elo' : '$elo',
      color: theme.colorScheme.secondary,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.lessonFinishedTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.check_circle,
          color: theme.colorScheme.secondary,
          size: AppIconSize.hero,
        ),
        SizedBox(height: AppSpacing.gap60),
        Row(
          children: [
            Expanded(child: StatWidget(statData: timeSpent)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: StatWidget(statData: accuracy)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: StatWidget(statData: eloStat)),
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
