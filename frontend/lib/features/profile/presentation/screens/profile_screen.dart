import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/locale_provider.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';
import 'package:goal_getter/features/profile/presentation/controllers/profile_controller.dart';
import 'package:goal_getter/features/profile/presentation/widgets/profile_header.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final AuthService _authService = ref.read(authServiceProvider);
  late final SettingsStorage _storage = ref.read(settingsStorageProvider);
  late bool _notificationsOn = _storage.readNotificationsOn();

  static const _languageNames = {
    SettingsStorage.english: 'English',
    SettingsStorage.portuguese: 'Português',
    SettingsStorage.spanish: 'Español',
    SettingsStorage.french: 'Français',
    SettingsStorage.german: 'Deutsch',
  };

  static const _languageFlags = {
    SettingsStorage.english: 'US',
    SettingsStorage.portuguese: 'BR',
    SettingsStorage.spanish: 'ES',
    SettingsStorage.french: 'FR',
    SettingsStorage.german: 'DE',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLanguage = ref.watch(localeProvider).languageCode;
    final profile = ref.watch(profileControllerProvider);
    final goalsCount =
        ref.watch(goalsListControllerProvider).value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              ProfileHeader(
                profile: profile,
                goalsCount: goalsCount,
                onRetry: () => ref.invalidate(profileControllerProvider),
              ),
              const SizedBox(height: 28),

              _goalsSection(l10n),
              const SizedBox(height: 28),

              _preferencesSection(l10n, currentLanguage),
              const SizedBox(height: 28),

              _buildLogoutButton(),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  l10n.profileVersionTag,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// "Goals": manage the existing ones, or start another.
  Widget _goalsSection(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l10n.goals),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.flag_outlined,
          title: l10n.manageGoals,
          subtitle: l10n.manageGoalsSubtitle,
          trailing: _chevron(),
          onTap: () => context.push(AppRoutes.goals),
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.add,
          iconTinted: true,
          title: l10n.createNewGoal,
          trailing: _chevron(),
          onTap: () => context.push(AppRoutes.goalPrompt),
        ),
      ],
    );
  }

  /// "Preferences": the app language, and the notifications switch.
  Widget _preferencesSection(AppLocalizations l10n, String currentLanguage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l10n.preferences),
        const SizedBox(height: 10),
        _tile(
          icon: Icons.language,
          title: l10n.language,
          trailing: Text(
            _languageNames[currentLanguage] ?? currentLanguage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: _showLanguagePicker,
        ),
        const SizedBox(height: 12),
        _tile(
          icon: Icons.notifications_none,
          title: l10n.notifications,
          trailing: Switch(
            value: _notificationsOn,
            onChanged: _setNotifications,
          ),
          onTap: () => _setNotifications(!_notificationsOn),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _chevron() => Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool iconTinted = false,
    VoidCallback? onTap,
  }) {
    final iconBg = iconTinted
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
        : Theme.of(context).colorScheme.surfaceContainer;
    final iconColor = iconTinted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _handleSignOut,
        icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
        label: Text(
          AppLocalizations.of(context).signOut,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }

  /// Persisted, so the switch survives a restart. Nothing reads it yet: the
  /// app sends no notifications.
  void _setNotifications(bool on) {
    setState(() => _notificationsOn = on);
    _storage.writeNotificationsOn(on: on);
  }

  void _showLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.chip)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languageNames.entries.map((e) {
              return ListTile(
                leading: SizedBox(
                  width: 32,
                  height: 24,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.hairline),
                    child: CountryFlag.fromCountryCode(
                      _languageFlags[e.key] ?? 'US',
                    ),
                  ),
                ),
                title: Text(e.value),
                onTap: () {
                  ref.read(localeProvider.notifier).setLanguage(e.key);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).signOut),
          content: Text(AppLocalizations.of(context).areYouSure),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(AppLocalizations.of(context).signOut),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Best-effort logout, then every stored key goes (see AuthService).
      await _authService.signOut();
      if (mounted) {
        context.go(AppRoutes.start);
      }
    }
  }
}
