import 'package:flutter/material.dart';
import '../utils/settings_storage.dart';
import 'about.dart';
import 'introduction_screen.dart';

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
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Section
            const Text(
              'Language:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Language Selection Buttons
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
              'How to use',
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
            
            // About Section
            _buildSectionTile(
              'About',
              Icons.info_outline,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
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