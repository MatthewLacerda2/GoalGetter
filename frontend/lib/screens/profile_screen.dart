import 'package:flutter/material.dart';
import '../utils/settings_storage.dart';
import '../l10n/app_localizations.dart';
import 'introduction_screen.dart';
import 'test_screen.dart';
import 'delete_all_screen.dart';

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
    
    // Notify the parent widget about the language change
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.language}:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageButton(
                    'EN',
                    SettingsStorage.english,
                    Icons.language,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageButton(
                    'PT',
                    SettingsStorage.portuguese,
                    Icons.language,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // How to Use Section
            _buildSectionTile(
              AppLocalizations.of(context)!.howToUse,
              Icons.help_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IntroductionScreenWidget(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            _buildSectionTile(
              'Test Screen',
              Icons.science,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            _buildSectionTile(
              'Delete All Data',
              Icons.delete_forever,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeleteAllScreen(),
                  ),
                );
              },
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary 
                : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary 
                  : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //For now we only use this once, but we will add sections in the future, so might as well leave it here
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
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}