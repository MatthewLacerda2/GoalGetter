import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bottom nav icon. Selected = accent; unselected = muted gray.
/// No border; icon tint only (per plan).
class MainScreenIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const MainScreenIcon({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppTheme.accentPrimary : AppTheme.textSecondary;
    return Icon(icon, color: color);
  }
}
