import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/features/profile/domain/user_profile.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The Profile header from GET /me: avatar, name, email, goal count, streak
/// and member-since. A failed load says so, with a retry, in its place.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.goalsCount,
    required this.onRetry,
  });

  final AsyncValue<UserProfile> profile;
  final int goalsCount;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return profile.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => FailureView(
        error: error,
        title: AppLocalizations.of(context).profileLoadFailed,
        onRetry: onRetry,
      ),
      data: (p) => _Header(profile: p, goalsCount: goalsCount),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.goalsCount});

  final UserProfile profile;
  final int goalsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium;
    return Row(
      children: [
        _Avatar(name: profile.name),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: theme.textTheme.titleLarge),
              Text(
                profile.email,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('$goalsCount ${l10n.goals.toLowerCase()}', style: muted),
                  Text(l10n.statSeparator, style: muted),
                  Icon(
                    Icons.local_fire_department,
                    size: 15,
                    color: scheme.secondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${profile.currentStreak}',
                    style: muted?.copyWith(
                      color: scheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.profileMemberSince(profile.memberSince.toLocal()),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The gradient circle carrying the student's initial.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: theme.textTheme.headlineLarge?.copyWith(
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}
