import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/locale_provider.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final AuthService _authService = ref.read(authServiceProvider);

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(localeProvider).languageCode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Text(
                  '${AppLocalizations.of(context)!.language}:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(width: 12.0),
                _buildLanguageButton(
                  'US',
                  SettingsStorage.english,
                  Icons.language,
                  currentLanguage,
                ),
                _buildLanguageButton(
                  'BR',
                  SettingsStorage.portuguese,
                  Icons.language,
                  currentLanguage,
                ),
                _buildLanguageButton(
                  'FR',
                  SettingsStorage.french,
                  Icons.language,
                  currentLanguage,
                ),
                _buildLanguageButton(
                  'ES',
                  SettingsStorage.spanish,
                  Icons.language,
                  currentLanguage,
                ),
                _buildLanguageButton(
                  'DE',
                  SettingsStorage.german,
                  Icons.language,
                  currentLanguage,
                ),
              ],
            ),

            SizedBox(height: 16),

            _buildSectionTile(
              AppLocalizations.of(context)!.goals,
              Icons.list,
              () {
                context.push(AppRoutes.goals);
              },
            ),

            SizedBox(height: 16),

            _buildSectionTile(
              AppLocalizations.of(context)!.createNewGoal,
              Icons.map,
              () {
                context.push(AppRoutes.goalPrompt);
              },
            ),

            SizedBox(height: 32.0),

            _buildSignOutButton(),
          ],
        ),
      ),
    ));
  }

  Widget _buildLanguageButton(
    String label,
    String language,
    IconData icon,
    String currentLanguage,
  ) {
    final isSelected = currentLanguage == language;

    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLanguage(language),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: SizedBox(
          width: 44,
          height: 32,
          child: CountryFlag.fromCountryCode(label),
        ),
      ),
    );
  }

  Widget _buildSectionTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSignOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
          padding: EdgeInsets.symmetric(vertical: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.signOut,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.signOut),
          content: Text(AppLocalizations.of(context)!.areYouSure),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: Text(AppLocalizations.of(context)!.signOut),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Clear auth data
      await _authService.signOut();

      // Clear user data from settings
      await SettingsStorage.clearAllUserData();

      // Navigate to start screen
      if (mounted) {
        context.go(AppRoutes.start);
      }
    }
  }
}
