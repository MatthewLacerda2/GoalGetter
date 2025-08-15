import 'package:flutter/material.dart';
import 'screens/task_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/tutor_screen.dart';
import 'screens/profile_screen.dart';
import 'l10n/app_localizations.dart';
import 'utils/settings_storage.dart';
import 'widgets/main_screen_icon.dart';
import 'models/fake_chat_message_array.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
  
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _tabPages => <Widget>[
    ResourcesScreen(),
    TutorScreen(messages: fakeChatMessages),
    TaskScreen(),
    LeaderBoardScreen(),
    ProfileScreen(onLanguageChanged: widget.onLanguageChanged),
  ];

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
        backgroundColor: Colors.grey[800],
        items: [
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.school,
              color: Colors.deepOrange,
              isSelected: _selectedIndex == 0,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.graphic_eq,
              color: Colors.purple,
              isSelected: _selectedIndex == 1,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.event_note,
              color: Colors.blue,
              isSelected: _selectedIndex == 2,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.workspace_premium_outlined,
              color: Colors.amber,
              isSelected: _selectedIndex == 3,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.person,
              color: Colors.blueGrey,
              isSelected: _selectedIndex == 4,
            ),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
