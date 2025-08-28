import 'package:flutter/material.dart';

class WeekdayColumn extends StatelessWidget {
  final String dayLabel;
  final bool isCompleted;
  final double width;

  const WeekdayColumn({
    super.key,
    required this.dayLabel,
    required this.isCompleted,
    this.width = 40,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? Colors.green : Colors.red,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

