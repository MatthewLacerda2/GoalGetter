import 'package:flutter/material.dart';
import 'screens/daily_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/roadmap_screen.dart';
import 'screens/tutor_screen.dart';
import 'screens/profile_screen.dart';
import 'l10n/app_localizations.dart';
import 'utils/settings_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final language = await SettingsStorage.getUserLanguage();
    setState(() {
      _locale = Locale(language);
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _locale = Locale(language);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoalGetter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(
        title: 'Goal Getter',
        onLanguageChanged: _changeLanguage,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.onLanguageChanged});

  final String title;
  final Function(String) onLanguageChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  List<Widget> get _tabPages => <Widget>[
    const RoadmapScreen(),
    const ResourcesScreen(),
    const TutorScreen(),
    const LeaderBoardScreen(),
    const DailyScreen(),
    ProfileScreen(onLanguageChanged: widget.onLanguageChanged),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed the AppBar here
      body: SafeArea(
        child: _tabPages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        iconSize: 28,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.flag, color: Colors.green),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_note, color: Colors.blueAccent),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person, color: Colors.grey),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
