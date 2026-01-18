import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/settings_storage.dart';
import 'list_goals_screen.dart';
import 'onboarding/goal_prompt_screen.dart';
import 'show_objectives_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Function(String)? onLanguageChanged;

  const ProfileScreen({super.key, this.onLanguageChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _currentLanguage = SettingsStorage.defaultLanguage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final language = await SettingsStorage.getUserLanguage();
    setState(() {
      _currentLanguage = language;
    });
  }

  Future<void> _changeLanguage(String language) async {
    await SettingsStorage.setUserLanguage(language);
    setState(() {
      _currentLanguage = language;
    });
    widget.onLanguageChanged?.call(language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${AppLocalizations.of(context)!.language}:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                _buildLanguageButton(
                  'US',
                  SettingsStorage.english,
                  Icons.language,
                ),
                _buildLanguageButton(
                  'BR',
                  SettingsStorage.portuguese,
                  Icons.language,
                ),
                _buildLanguageButton(
                  'FR',
                  SettingsStorage.french,
                  Icons.language,
                ),
                _buildLanguageButton(
                  'ES',
                  SettingsStorage.spanish,
                  Icons.language,
                ),
                _buildLanguageButton(
                  'DE',
                  SettingsStorage.german,
                  Icons.language,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionTile('Goals', Icons.list, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListGoalsScreen(),
                ),
              );
            }),

            const SizedBox(height: 16),

            _buildSectionTile('Show objectives', Icons.checklist, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShowObjectivesScreen(),
                ),
              );
            }),

            const SizedBox(height: 16),

            _buildSectionTile('Create a new goal', Icons.map, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalPromptScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String label, String language, IconData icon) {
    final isSelected = _currentLanguage == language;

    return GestureDetector(
      onTap: () => _changeLanguage(language),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
