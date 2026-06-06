import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
class MissionsScreen extends StatelessWidget {
  MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.comingSoon,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
