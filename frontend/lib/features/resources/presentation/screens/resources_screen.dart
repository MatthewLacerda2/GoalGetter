import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/resources/presentation/widgets/resource_tab.dart';
import 'package:goal_getter/features/resources/presentation/controllers/resources_controller.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourcesProvider);

    return resourcesAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Error loading resources',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  err.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => ref.refresh(resourcesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (mockData) {
        final youtube = mockData['youtube'] ?? [];
        final sites = mockData['sites'] ?? [];
        final books = mockData['books'] ?? [];

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            toolbarHeight: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              dividerHeight: 1,
              dividerColor: Theme.of(context).colorScheme.outline,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  icon: const Icon(Icons.play_circle_outline, size: 22),
                  text: AppLocalizations.of(context).videos,
                ),
                Tab(
                  icon: const Icon(Icons.menu_book_outlined, size: 22),
                  text: AppLocalizations.of(context).guides,
                ),
                Tab(
                  icon: const Icon(Icons.public, size: 22),
                  text: AppLocalizations.of(context).sites,
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ResourceTab(resources: youtube),
              ResourceTab(resources: books),
              ResourceTab(resources: sites),
            ],
          ),
        );
      },
    );
  }
}
