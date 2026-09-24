import 'package:flutter/material.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

class InfoScreen extends StatelessWidget {
  final IconData icon;
  final String descriptionText;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? title;

  InfoScreen({
    super.key,
    required this.icon,
    required this.descriptionText,
    required this.buttonText,
    required this.onButtonPressed,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Expanded(
                child: _InfoBody(
                  icon: icon,
                  title: title,
                  descriptionText: descriptionText,
                ),
              ),
              _InfoButton(label: buttonText, onPressed: onButtonPressed),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// The optional headline, the illustration icon, and the message in its box.
class _InfoBody extends StatelessWidget {
  const _InfoBody({
    required this.icon,
    required this.title,
    required this.descriptionText,
  });

  final IconData icon;
  final String? title;
  final String descriptionText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24.0),
        ],
        Icon(icon, color: theme.colorScheme.secondary, size: 140),
        SizedBox(height: 48),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            descriptionText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// The screen's single action, pinned to the bottom.
class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: scheme.onPrimary),
        ),
      ),
    );
  }
}
