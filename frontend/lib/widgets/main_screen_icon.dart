import 'package:flutter/material.dart';

class MainScreenIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;

  const MainScreenIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color),
    );
  }
}