import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/missions_screen.dart';
import '../../screens/objective_screen.dart';
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
    required this.onLanguageChanged,
    this.selectedIndex = 0,
  });

  final String title;
  final ValueChanged<String> onLanguageChanged;
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
      const ObjectiveScreen(),
      const MissionsScreen(),
      const TutorScreen(),
      const MissionsScreen(), //TODO: placeholder while StatsScreen is not implemented
      //StatsScreen(),
      const ResourcesScreen(),
      ProfileScreen(onLanguageChanged: widget.onLanguageChanged),
    ];

    _selectedIndex = widget.selectedIndex.clamp(0, _tabPages.length - 1);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index.clamp(0, _tabPages.length - 1);
    });
  }

  List<BottomNavigationBarItem> get _bottomNavItems {
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.event_note,
          color: Colors.green,
          isSelected: _selectedIndex == 0,
        ),
        label: AppLocalizations.of(context)!.objective,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.flag,
          color: Colors.orange,
          isSelected: _selectedIndex == 1,
        ),
        label: 'Missions',
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.graphic_eq,
          color: Colors.purpleAccent,
          isSelected: _selectedIndex == 2,
        ),
        label: AppLocalizations.of(context)!.tutor,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.emoji_events,
          color: Colors.blue,
          isSelected: _selectedIndex == 3,
        ),
        label: AppLocalizations.of(context)!.awards,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.school,
          color: Colors.deepOrange,
          isSelected: _selectedIndex == 4,
        ),
        label: AppLocalizations.of(context)!.resources,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.person,
          color: Colors.blueGrey,
          isSelected: _selectedIndex == 5,
        ),
        label: AppLocalizations.of(context)!.profile,
      ),
    ];

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 33, 33, 33),
        child: SafeArea(
          child: IndexedStack(index: _selectedIndex, children: _tabPages),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 28,
        backgroundColor: const Color.fromARGB(255, 11, 11, 11),
        enableFeedback: false,
        items: _bottomNavItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
