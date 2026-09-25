import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/dev/dev_fixtures.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// A dev-only index of every screen in the app.
///
/// Entry point while the backend is mocked: it makes each screen reachable in
/// one tap, including the ones that need a rich `extra` object and would
/// otherwise only be reachable by walking the whole flow (see [DevFixtures]).
/// Shown instead of the normal splash when the app is built with
/// `--dart-define=DEV_MENU=true`; it is never reachable in a production build.
class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  static const _entries = <_DevSection>[
    _DevSection('Onboarding', [
      _DevEntry('Start / sign-in', Icons.login, AppRoutes.start),
      _DevEntry('Goal prompt', Icons.edit_note, AppRoutes.goalPrompt),
      _DevEntry('Goal questions', Icons.quiz_outlined,
          AppRoutes.devGoalQuestions),
      _DevEntry('Study plan', Icons.description_outlined,
          AppRoutes.devStudyPlan),
      _DevEntry('Standard questions', Icons.fact_check_outlined,
          AppRoutes.devStandardQuestions),
    ]),
    _DevSection('Main tabs', [
      _DevEntry('Home dashboard', Icons.home_outlined, AppRoutes.home),
      _DevEntry('Tutor chat', Icons.chat_bubble_outline, AppRoutes.tutor),
      _DevEntry('Resources', Icons.menu_book_outlined, AppRoutes.resources),
      _DevEntry('Profile', Icons.person_outline, AppRoutes.profile),
    ]),
    _DevSection('Lessons', [
      _DevEntry('Lesson (run it)', Icons.play_circle_outline, AppRoutes.lesson),
      _DevEntry('Lesson finished', Icons.emoji_events_outlined,
          AppRoutes.lessonFinish,
          needsArgs: true),
      _DevEntry('Info screen', Icons.info_outline, AppRoutes.devInfoScreen),
    ]),
    _DevSection('Goals', [
      _DevEntry('Goals list', Icons.flag_outlined, AppRoutes.goals),
      _DevEntry('Goal detail', Icons.article_outlined, AppRoutes.devGoalDetail,
          needsArgs: true),
    ]),
  ];

  /// The `extra` payload a route needs, or null when it takes none.
  static Object? _extraFor(String route) {
    switch (route) {
      case AppRoutes.lessonFinish:
        return DevFixtures.finishLesson;
      case AppRoutes.devGoalDetail:
        return DevFixtures.goalDetail;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dev — all screens'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.xs,
              right: AppSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Every screen runs on mock data. Back returns here.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          for (final section in _entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                section.title.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final entry in section.entries)
              _DevTile(entry: entry, extra: _extraFor(entry.route)),
          ],
        ],
      ),
    );
  }
}

class _DevSection {
  final String title;
  final List<_DevEntry> entries;
  const _DevSection(this.title, this.entries);
}

class _DevEntry {
  final String label;
  final IconData icon;
  final String route;

  /// True when the route reads a rich object from `extra`; surfaced in the UI
  /// so it is obvious which screens cannot simply be deep-linked by URL.
  final bool needsArgs;

  const _DevEntry(this.label, this.icon, this.route, {this.needsArgs = false});
}

class _DevTile extends StatelessWidget {
  const _DevTile({required this.entry, this.extra});

  final _DevEntry entry;
  final Object? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(entry.icon, color: theme.colorScheme.primary),
      title: Text(entry.label),
      subtitle: Text(
        entry.route,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: entry.needsArgs
          ? Icon(Icons.data_object,
              size: 18, color: theme.colorScheme.onSurfaceVariant)
          : const Icon(Icons.chevron_right, size: 18),
      // push (not go) so the device back button returns to this menu.
      onTap: () => context.push(entry.route, extra: extra),
    );
  }
}
