import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/widgets/main_screen_icon.dart';

/// The authenticated area's bottom-navigation scaffold.
///
/// Hosts the [StatefulNavigationShell] from go_router's
/// `StatefulShellRoute.indexedStack`, which preserves each tab's own navigation
/// stack and state. Tabs: Home, Tutor, Resources, Profile.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab returns it to its initial route.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<BottomNavigationBarItem> _navItems(BuildContext context) {
    final current = navigationShell.currentIndex;
    return [
      BottomNavigationBarItem(
        icon: MainScreenIcon(icon: Icons.home_outlined, isSelected: current == 0),
        label: AppLocalizations.of(context)!.home,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.chat_bubble_outline,
          isSelected: current == 1,
        ),
        label: AppLocalizations.of(context)!.tutor,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.menu_book_outlined,
          isSelected: current == 2,
        ),
        label: AppLocalizations.of(context)!.resources,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.person_outline,
          isSelected: current == 3,
        ),
        label: AppLocalizations.of(context)!.profile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: navigationShell),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 28,
        enableFeedback: false,
        items: _navItems(context),
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
