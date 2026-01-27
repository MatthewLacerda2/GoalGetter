import 'package:flutter/material.dart';

import '../../../screens/objective/lesson_screen.dart';
import '../../../theme/app_theme.dart';

class LessonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const LessonButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LessonScreen(),
                ),
              );
            },
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacing16,
            horizontal: AppTheme.spacing24,
          ),
          decoration: BoxDecoration(
            color: AppTheme.accentPrimary,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSize18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
