import 'package:flutter/material.dart';

/// Bottom nav icon. Selected = accent; unselected = muted gray.
/// No border; icon tint only (per plan).
class MainScreenIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  MainScreenIcon({
    super.key,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
    return Icon(icon, color: color);
  }
}
