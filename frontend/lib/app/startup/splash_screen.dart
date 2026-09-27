import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/app/startup/app_start_controller.dart';

/// The `/` splash: a spinner while [launchDestinationProvider] decides where
/// the app opens.
///
/// It never navigates. Watching the provider is what starts the decision and
/// keeps it alive while the splash is up; the router's redirect on `/` reads
/// the answer and moves the student on.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(launchDestinationProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(child: CircularProgressIndicator(color: colors.primary)),
    );
  }
}
