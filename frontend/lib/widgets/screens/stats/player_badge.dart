import 'package:flutter/material.dart';

class PlayerBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final double fontSize;
  final Color? iconColor;
  final Color? textColor;

  const PlayerBadge({
    super.key,
    required this.icon,
    required this.text,
    this.fontSize = 12,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color.fromARGB(80, 200, 200, 200), width: 2.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: iconColor ?? Colors.blue,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
