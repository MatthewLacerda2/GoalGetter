import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class InfoScreen extends StatelessWidget {
  final IconData icon;
  final String descriptionText;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? title;

  const InfoScreen({
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
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing24),
                    ],
                    Icon(
                      icon,
                      color: AppTheme.accentSecondary,
                      size: 140,
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing24,
                        vertical: AppTheme.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius),
                      ),
                      child: Text(
                        descriptionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: AppTheme.fontSize20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.cardRadius),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
            ],
          ),
        ),
      ),
    );
  }
}