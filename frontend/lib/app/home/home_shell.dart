import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import '../../screens/missions_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/resources_screen.dart';
import '../../screens/tutor_screen.dart';
import '../../widgets/main_screen_icon.dart';

/// The main authenticated area of the app.
///
/// NOTE: This is extracted from `main.dart` as a first refactor step.
/// A later step will rename this to `HomeShell` and migrate call sites to
/// named routes.
class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.selectedIndex = 0,
  });

  final String title;
  final int selectedIndex;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex;
  late final List<Widget> _tabPages;

  @override
  void initState() {
    super.initState();
    _tabPages = [
      MissionsScreen(),
      TutorScreen(),
      ResourcesScreen(),
      ProfileScreen(),
    ];

    _selectedIndex = widget.selectedIndex.clamp(0, _tabPages.length - 1);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index.clamp(0, _tabPages.length - 1);
    });
  }

  List<BottomNavigationBarItem> get _bottomNavItems {
    return [
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.flag,
          isSelected: _selectedIndex == 0,
        ),
        label: 'Missions',
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.graphic_eq,
          isSelected: _selectedIndex == 1,
        ),
        label: AppLocalizations.of(context)!.tutor,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.school,
          isSelected: _selectedIndex == 2,
        ),
        label: AppLocalizations.of(context)!.resources,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.person,
          isSelected: _selectedIndex == 3,
        ),
        label: AppLocalizations.of(context)!.profile,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _tabPages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 28,
        enableFeedback: false,
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
