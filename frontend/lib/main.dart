import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'screens/objective_screen.dart';
import 'screens/onboarding/start_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/resources_screen.dart';
import 'screens/stats_screen.dart';
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
      // User has completed onboarding - check for stored goal/objective IDs
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
  bool _showResourcesTab = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _initializeResourcesTab();
  }

  Future<void> _initializeResourcesTab() async {
    // First, check SharedPreferences to see if we should show the tab initially
    final hasResourcesInPrefs = await SettingsStorage.hasResources();

    setState(() {
      _showResourcesTab = hasResourcesInPrefs;
    });

    // Then fetch from API regardless
    await _fetchResources();
  }

  Future<void> _fetchResources() async {
    try {
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        setState(() {
          _showResourcesTab = false;
        });
        await SettingsStorage.setHasResources(false);
        return;
      }

      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

      // Get student status to get goalId
      final studentApi = StudentApi(apiClient);
      final studentResponse = await studentApi
          .getStudentCurrentStatusApiV1StudentGet();

      if (studentResponse == null) {
        setState(() {
          _showResourcesTab = false;
        });
        await SettingsStorage.setHasResources(false);
        return;
      }

      // Fetch resources
      final resourcesApi = ResourcesApi(apiClient);
      final resourcesResponse = await resourcesApi
          .getResourcesApiV1ResourcesGet(studentResponse.goalId!);

      final hasResources =
          resourcesResponse != null && resourcesResponse.resources.isNotEmpty;

      if (mounted) {
        setState(() {
          final previousShowResources = _showResourcesTab;
          _showResourcesTab = hasResources;

          // Adjust selected index if resources tab visibility changed
          if (previousShowResources != hasResources) {
            // If resources tab was removed and we were on it or profile, adjust
            if (!hasResources && previousShowResources) {
              if (_selectedIndex == 3) {
                // Was on resources, move to stats
                _selectedIndex = 2;
              } else if (_selectedIndex == 4) {
                // Was on profile, keep on profile (now index 3)
                _selectedIndex = 3;
              }
            } else if (hasResources && !previousShowResources) {
              // If resources tab was added and we were on profile, adjust
              if (_selectedIndex == 3) {
                // Was on profile, keep on profile (now index 4)
                _selectedIndex = 4;
              }
            }
          }
        });
        await SettingsStorage.setHasResources(hasResources);
      }
    } catch (e) {
      // On error, hide the tab
      if (mounted) {
        setState(() {
          _showResourcesTab = false;
        });
        await SettingsStorage.setHasResources(false);
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _tabPages {
    final pages = <Widget>[
      ObjectiveScreen(),
      const TutorScreen(),
      StatsScreen(),
    ];

    if (_showResourcesTab) {
      pages.add(ResourcesScreen());
    }

    pages.add(ProfileScreen(onLanguageChanged: widget.onLanguageChanged));

    return pages;
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
          icon: Icons.graphic_eq,
          color: Colors.purpleAccent,
          isSelected: _selectedIndex == 1,
        ),
        label: AppLocalizations.of(context)!.tutor,
      ),
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.emoji_events,
          color: Colors.blue,
          isSelected: _selectedIndex == 2,
        ),
        label: AppLocalizations.of(context)!.awards,
      ),
    ];

    if (_showResourcesTab) {
      items.add(
        BottomNavigationBarItem(
          icon: MainScreenIcon(
            icon: Icons.school,
            color: Colors.deepOrange,
            isSelected: _selectedIndex == 3,
          ),
          label: AppLocalizations.of(context)!.resources,
        ),
      );
    }

    // Profile is always last
    final profileIndex = _showResourcesTab ? 4 : 3;
    items.add(
      BottomNavigationBarItem(
        icon: MainScreenIcon(
          icon: Icons.person,
          color: Colors.blueGrey,
          isSelected: _selectedIndex == profileIndex,
        ),
        label: AppLocalizations.of(context)!.profile,
      ),
    );

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
