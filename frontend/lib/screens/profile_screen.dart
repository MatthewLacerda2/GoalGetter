import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';
import '../utils/settings_storage.dart';
import 'list_goals_screen.dart';
import 'list_memories_screen.dart';
import 'onboarding/goal_prompt_screen.dart';
import 'onboarding/start_screen.dart';
import 'show_objectives_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(localeProvider).languageCode;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.edgePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Text(
                  '${AppLocalizations.of(context)!.language}:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: AppTheme.spacing12),
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

            const SizedBox(height: 16),

            _buildSectionTile(
              AppLocalizations.of(context)!.goals,
              Icons.list,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListGoalsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildSectionTile(
              AppLocalizations.of(context)!.showObjectives,
              Icons.checklist,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShowObjectivesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildSectionTile(
              AppLocalizations.of(context)!.listMemories,
              Icons.memory,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListMemoriesScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _buildSectionTile(
              AppLocalizations.of(context)!.createNewGoal,
              Icons.map,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GoalPromptScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppTheme.spacing32),

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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.spacing4),
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
        borderRadius: BorderRadius.circular(AppTheme.spacing8),
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
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
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
          backgroundColor: AppTheme.error.withValues(alpha: 0.2),
          foregroundColor: AppTheme.error,
          side: const BorderSide(
            color: AppTheme.error,
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.spacing8),
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
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const StartScreen()),
          (route) => false,
        );
      }
    }
  }
}
