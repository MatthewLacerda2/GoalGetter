import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/error_text.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/resources/data/resources_api.dart';
import 'package:goal_getter/features/resources/domain/resource_item.dart';
import 'package:goal_getter/features/resources/presentation/widgets/resource_tab.dart';
import 'package:goal_getter/features/resources/presentation/controllers/resources_controller.dart';

/// The active goal's resources (`GET /resources`), one tab per kind.
///
/// Four states, never confused: loading; failed, with a retry; no active goal
/// (404 `No active goal`), with a way to pick one, since a retry would get the
/// same answer; and loaded, where three empty lists mean the background search
/// is still running, which is said as such rather than shown as an error.
class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  static bool isNoActiveGoal(Object error) =>
      error is ApiException &&
      error.status == 404 &&
      error.detail == ResourcesApi.noActiveGoalDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final resourcesAsync = ref.watch(resourcesProvider);
    void reload() => ref.invalidate(resourcesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: resourcesAsync.when(
          skipLoadingOnRefresh: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => isNoActiveGoal(err)
              ? StateMessage(
                  icon: Icons.flag_outlined,
                  title: l10n.resourcesNoActiveGoal,
                  body: l10n.resourcesNoActiveGoalBody,
                  actionLabel: l10n.pickAGoal,
                  onAction: () => context.push(AppRoutes.goals),
                )
              : StateMessage(
                  icon: Icons.error_outline,
                  isError: true,
                  title: l10n.resourcesLoadFailed,
                  body: errorText(err, l10n),
                  actionLabel: l10n.retry,
                  onAction: reload,
                ),
          data: (resources) => resources.isEmpty
              ? StateMessage(
                  icon: Icons.travel_explore,
                  title: l10n.resourcesStillLooking,
                  body: l10n.resourcesStillLookingBody,
                  actionLabel: l10n.checkAgain,
                  onAction: reload,
                )
              : _ResourceTabs(resources: resources),
        ),
      ),
    );
  }
}

class _ResourceTabs extends StatelessWidget {
  const _ResourceTabs({required this.resources});

  final GoalResources resources;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            dividerHeight: 1,
            dividerColor: scheme.outline,
            indicatorColor: scheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                icon: const Icon(Icons.play_circle_outline, size: 22),
                text: '${l10n.videos} (${resources.youtube.length})',
              ),
              Tab(
                icon: const Icon(Icons.menu_book_outlined, size: 22),
                text: '${l10n.guides} (${resources.books.length})',
              ),
              Tab(
                icon: const Icon(Icons.public, size: 22),
                text: '${l10n.sites} (${resources.websites.length})',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ResourceTab(resources: resources.youtube),
                ResourceTab(resources: resources.books),
                ResourceTab(resources: resources.websites),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
