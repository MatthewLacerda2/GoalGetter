import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/core/utils/locale_provider.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';

/// Each language by its own name: a student who cannot read the current one
/// still finds his.
const languageNames = {
  SettingsStorage.english: 'English',
  SettingsStorage.portuguese: 'Português',
  SettingsStorage.spanish: 'Español',
  SettingsStorage.french: 'Français',
  SettingsStorage.german: 'Deutsch',
};

const _languageFlags = {
  SettingsStorage.english: 'US',
  SettingsStorage.portuguese: 'BR',
  SettingsStorage.spanish: 'ES',
  SettingsStorage.french: 'FR',
  SettingsStorage.german: 'DE',
};

/// The flag of [language], at the size the pickers draw it.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag(this.language, {super.key});

  final String language;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 24,
      child: ClipRRect(
        borderRadius: AppRadius.hairlineBorder,
        child: CountryFlag.fromCountryCode(_languageFlags[language] ?? 'US'),
      ),
    );
  }
}

/// The sheet listing the five languages. Picking one changes the app's
/// language at once ([LocaleNotifier.setLanguage]); [onPicked] runs after.
///
/// One picker for the start screen and the profile (#172), so the two can
/// never offer different languages.
void showLanguagePicker(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onPicked,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.chip)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: languageNames.entries.map((e) {
            return ListTile(
              leading: LanguageFlag(e.key),
              title: Text(e.value),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await ref.read(localeProvider.notifier).setLanguage(e.key);
                onPicked?.call();
              },
            );
          }).toList(),
        ),
      );
    },
  );
}

/// The start screen's language: the current one as a flag and a name, and a
/// tap opens [showLanguagePicker]. It starts at the phone's language
/// ([LocaleNotifier]), so most students never touch it.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider).languageCode;
    return TextButton.icon(
      onPressed: () => showLanguagePicker(context, ref),
      icon: LanguageFlag(language),
      label: Text(languageNames[language] ?? language),
    );
  }
}
