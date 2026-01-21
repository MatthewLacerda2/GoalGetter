import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../screens/onboarding/goal_prompt_screen.dart';
import '../screens/onboarding/start_screen.dart';
import 'home/home_shell.dart';
import 'startup/auth_gate.dart';

class AppRoutes {
  static const root = '/';
  static const start = '/start';
  static const goalPrompt = '/goalPrompt';
  static const home = '/home';
}

class HomeRouteArgs {
  const HomeRouteArgs({this.selectedIndex = 0});

  final int selectedIndex;
}

class GoalGetterApp extends StatefulWidget {
  const GoalGetterApp({super.key, required this.initialLocale});

  final Locale initialLocale;

  @override
  State<GoalGetterApp> createState() => _GoalGetterAppState();
}

class _GoalGetterAppState extends State<GoalGetterApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void _changeLanguage(String language) {
    setState(() {
      _locale = Locale(language);
    });
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.root:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AuthGate(),
        );

      case AppRoutes.start:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const StartScreen(),
        );

      case AppRoutes.goalPrompt:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GoalPromptScreen(),
        );

      case AppRoutes.home:
        final args = settings.arguments;
        final homeArgs = args is HomeRouteArgs ? args : const HomeRouteArgs();

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MyHomePage(
            title: 'Goal Getter',
            onLanguageChanged: _changeLanguage,
            selectedIndex: homeArgs.selectedIndex,
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const StartScreen(),
        );
    }
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
      onGenerateRoute: _onGenerateRoute,
      initialRoute: AppRoutes.root,
    );
  }
}
