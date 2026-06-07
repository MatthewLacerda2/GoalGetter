import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/error_retry_widget.dart';
import 'package:goal_getter/features/home/debug/mock_home_screen.dart';
import 'package:goal_getter/features/home/presentation/controllers/home_controller.dart';
import 'package:goal_getter/features/home/presentation/widgets/elo_chart.dart';
import 'package:goal_getter/features/home/presentation/widgets/recent_lessons_list.dart';
import 'package:goal_getter/features/home/presentation/widgets/start_lesson_button.dart';
import 'package:goal_getter/features/home/presentation/widgets/streak_chip.dart';

/// The landing dashboard shown to a logged-in user (the first bottom-nav tab).
///
/// Headerless by design: a clean top row (active goal + streak), the primary
/// "start lesson" CTA, recent lessons, and an elo-progress chart. Data is
/// scoped to the active goal, which is chosen from the Profile goals list.
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
          error: (err, _) => ErrorRetryWidget(
            errorMessage: err.toString(),
            onRetry: () => ref.invalidate(homeControllerProvider),
          ),
          data: (data) => data.goalName == null
              ? _EmptyState()
              : _Dashboard(data: data),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final MockHomeData data;

  const _Dashboard({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.goalName!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${l10n.elo} ${data.currentElo}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              const StreakChip(),
            ],
          ),
          const SizedBox(height: 28.0),
          const StartLessonButton(),
          const SizedBox(height: 32.0),
          RecentLessonsList(lessons: data.recentLessons),
          const SizedBox(height: 32.0),
          EloChart(history: data.eloHistory),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 96,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24.0),
            Text(
              l10n.noActiveGoal,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(AppRoutes.goalPrompt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text(
                  l10n.createGoal,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
