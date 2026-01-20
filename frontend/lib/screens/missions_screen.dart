import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.comingSoon,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
