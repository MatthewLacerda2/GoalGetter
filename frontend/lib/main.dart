import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'screens/missions_screen.dart';
import 'screens/objective_screen.dart';
import 'screens/onboarding/start_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/tutor_screen.dart';
import 'services/auth_service.dart';
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
  final AuthService _authService = AuthService();

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
      home: AuthWrapper(
        title: 'Goal Getter',
        onLanguageChanged: _changeLanguage,
        authService: _authService,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({
    super.key,
    required this.title,
    required this.onLanguageChanged,
    required this.authService,
  });

  final String title;
  final Function(String) onLanguageChanged;
  final AuthService authService;

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Check if user is signed in (has stored access token OR Google token)
    final hasAccessToken = await widget.authService.isSignedIn();
    final hasGoogleToken = await widget.authService.getStoredGoogleToken();
    final isSignedIn =
        hasAccessToken || (hasGoogleToken != null && hasGoogleToken.isNotEmpty);

    if (isSignedIn && hasAccessToken) {
      // User has account - check for stored goal/objective IDs and fetch status
      final storedGoalId = await SettingsStorage.getCurrentGoalId();
      final storedObjectiveId = await SettingsStorage.getCurrentObjectiveId();

      if (storedGoalId == null || storedObjectiveId == null) {
        // Fetch current goal/objective from API and store them
        try {
          final accessToken = await widget.authService.getStoredAccessToken();
          if (accessToken != null) {
            final apiClient = ApiClient(basePath: AppConfig.baseUrl);
            apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

            final studentApi = StudentApi(apiClient);
            final studentResponse = await studentApi
                .getStudentCurrentStatusApiV1StudentGet();

            if (studentResponse != null) {
              if (studentResponse.goalId != null &&
                  studentResponse.goalId!.isNotEmpty) {
                await SettingsStorage.setCurrentGoalId(studentResponse.goalId!);

                // Get objective ID
                final objectiveApi = ObjectiveApi(apiClient);
                final objectiveResponse = await objectiveApi
                    .getObjectiveApiV1ObjectiveGet();
                if (objectiveResponse != null) {
                  await SettingsStorage.setCurrentObjectiveId(
                    objectiveResponse.id,
                  );
                }
              } else {
                // User has no goals - navigate to goal prompt
                setState(() {
                  _hasCompletedOnboarding = false;
                  _isLoading = false;
                });
                return;
              }
            }
          }
        } catch (e) {
          // On error, continue with normal flow
        }
      }
    } else if (isSignedIn && !hasAccessToken && hasGoogleToken != null) {
      // User has Google token but no JWT token (account exists but might not have completed a goal)
      // This shouldn't happen normally after signup, but handle it gracefully
      setState(() {
        _hasCompletedOnboarding = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _hasCompletedOnboarding = isSignedIn && hasAccessToken;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 33, 33, 33),
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_hasCompletedOnboarding) {
      return MyHomePage(
        title: widget.title,
        onLanguageChanged: widget.onLanguageChanged,
      );
    } else {
      // User is not signed in or hasn't completed onboarding - show start screen
      return const StartScreen();
    }
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

  List<Widget> get _tabPages {
    return [
      ObjectiveScreen(),
      const MissionsScreen(),
      const TutorScreen(),
      const MissionsScreen(), //TODO: placeholder while StatsScreen is not implemented
      //StatsScreen(),
      const ResourcesScreen(),
      ProfileScreen(onLanguageChanged: widget.onLanguageChanged),
    ];
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
    // Ensure selected index is valid
    if (_selectedIndex >= _tabPages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 33, 33, 33),
        child: SafeArea(child: _tabPages[_selectedIndex]),
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
