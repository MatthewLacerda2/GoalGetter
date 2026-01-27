import 'package:flutter/material.dart';

import '../app.dart';
import '../../theme/app_theme.dart';
import 'app_start_controller.dart';

/// Startup gate that decides the initial screen.
///
/// It delegates startup/auth/onboarding decisions to [AppStartController].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, AppStartController? controller})
    : _controller = controller;

  final AppStartController? _controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<AppStartResult> _future;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _future = (widget._controller ?? AppStartController()).evaluate();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppStartResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentPrimary),
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
          backgroundColor: AppTheme.background,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.accentPrimary),
          ),
        );
      },
    );
  }
}
