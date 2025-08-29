import 'package:flutter/material.dart';
import 'package:goal_getter/models/fake_chat_message_array.dart';
import 'screens/objective_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/tutor_screen.dart';
import 'screens/profile_screen.dart';
import 'l10n/app_localizations.dart';
import 'utils/settings_storage.dart';
import 'widgets/main_screen_icon.dart';

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
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
  const MyHomePage({
    super.key, 
    required this.title, 
    required this.onLanguageChanged,
    this.selectedIndex = 0,
  });

  final String title;
  final Function(String) onLanguageChanged;
  final int selectedIndex;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _tabPages => <Widget>[
    ObjectiveScreen(),
    TutorScreen(messages: fakeChatMessages),
    StatsScreen(),
    ResourcesScreen(),
    ProfileScreen(onLanguageChanged: widget.onLanguageChanged),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 33, 33, 33),
        child: SafeArea(
          child: _tabPages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        iconSize: 28,
        backgroundColor: const Color.fromARGB(255, 11, 11, 11),
        enableFeedback: false,
        items: [
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.event_note,
              color: Colors.green,
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
              icon: Icons.workspace_premium_outlined,
              color: Colors.amber,
              isSelected: _selectedIndex == 2,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.school,
              color: Colors.deepOrange,
              isSelected: _selectedIndex == 3,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: MainScreenIcon(
              icon: Icons.person,
              color: Colors.white,
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
