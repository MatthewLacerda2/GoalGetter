import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/home/domain/home_dashboard.dart';
import 'package:goal_getter/features/home/presentation/controllers/home_controller.dart';
import 'package:goal_getter/features/home/presentation/widgets/elo_chip.dart';
import 'package:goal_getter/features/home/presentation/widgets/recent_lessons_list.dart';
import 'package:goal_getter/features/home/presentation/widgets/start_lesson_button.dart';
import 'package:goal_getter/features/home/presentation/widgets/streak_chip.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// The landing dashboard shown to a logged-in user (the first bottom-nav tab).
///
/// Headerless by design: a clean top row (active goal + streak), the primary
/// "start lesson" CTA and the recent lessons. Data is scoped to the active
/// goal, which is chosen from the Profile goals list.
///
/// The elo progress chart is not here: the rating has no per-day history to
/// draw while #62 is open, and an always-empty chart card reads as broken.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: homeAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          error: (err, _) => FailureView(
            error: err,
            title: AppLocalizations.of(context).homeLoadFailed,
            onRetry: () => ref.invalidate(homeControllerProvider),
          ),
          // null: 404 No active goal.
          data: (data) =>
              data == null ? const _EmptyState() : _Dashboard(data: data),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final HomeDashboard data;

  const _Dashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: elo (left) · goal name (centered) · streak (right).
          Row(
            children: [
              EloChip(elo: data.currentElo),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    data.goalName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              StreakChip(count: data.currentStreak),
            ],
          ),
          const SizedBox(height: 20.0),
          const StartLessonButton(),
          const SizedBox(height: 20.0),
          RecentLessonsList(lessons: data.recentLessons),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StateMessage(
      icon: Icons.flag_outlined,
      title: l10n.noActiveGoal,
      actionLabel: l10n.createGoal,
      onAction: () => context.push(AppRoutes.goalPrompt),
    );
  }
}
