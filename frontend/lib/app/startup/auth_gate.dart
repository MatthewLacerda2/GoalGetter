import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/app/app.dart';
import 'package:goal_getter/app/startup/app_start_controller.dart';

/// Startup gate that decides the initial screen.
///
/// It delegates startup/auth/onboarding decisions to [AppStartController].
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  late final Future<AppStartResult> _future;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(appStartControllerProvider).evaluate();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppStartResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            ),
          );
        }

        final result = snapshot.data;
        final destination = result?.destination;

        if (!_hasNavigated) {
          _hasNavigated = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final String routeName;
            if (destination == AppStartDestination.authenticatedReady) {
              routeName = AppRoutes.home;
            } else if (destination ==
                AppStartDestination.authenticatedNeedsGoal) {
              routeName = AppRoutes.goalPrompt;
            } else {
              routeName = AppRoutes.start;
            }

            Navigator.of(context).pushReplacementNamed(routeName);
          });
        }

        // Keep showing a stable loading UI while we navigate.
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          ),
        );
      },
    );
  }
}
