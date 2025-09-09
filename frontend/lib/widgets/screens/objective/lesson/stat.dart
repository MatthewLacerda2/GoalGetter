import 'package:flutter/material.dart';
import 'stat_data.dart';

//We will have separate lessons in the future, so might as well make separate stats to use on the finish lesson screen
class StatWidget extends StatelessWidget {
  final StatData statData;

  const StatWidget({
    super.key,
    required this.statData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: statData.color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: statData.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              statData.title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statData.icon,
                  color: statData.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  statData.text,
                  style: TextStyle(
                    color: statData.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}