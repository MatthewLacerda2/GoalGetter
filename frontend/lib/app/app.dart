import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/goal_prompt_screen.dart';
import 'package:goal_getter/features/onboarding/presentation/screens/start_screen.dart';
import 'package:goal_getter/services/providers.dart';
import 'package:goal_getter/app/home/home_shell.dart';
import 'package:goal_getter/features/auth/presentation/screens/auth_gate.dart';

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

class GoalGetterApp extends ConsumerWidget {
  const GoalGetterApp({super.key, required this.initialLocale});

  final Locale initialLocale;

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.root:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGate(),
        );

      case AppRoutes.start:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => StartScreen(),
        );

      case AppRoutes.goalPrompt:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => GoalPromptScreen(),
        );

      case AppRoutes.home:
        final args = settings.arguments;
        final homeArgs = args is HomeRouteArgs ? args : const HomeRouteArgs();

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MyHomePage(
            title: 'Goal Getter',
            selectedIndex: homeArgs.selectedIndex,
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => StartScreen(),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'GoalGetter',
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: _onGenerateRoute,
      initialRoute: AppRoutes.root,
    );
  }
}
