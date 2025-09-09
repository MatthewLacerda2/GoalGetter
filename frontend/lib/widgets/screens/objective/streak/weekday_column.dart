import 'package:flutter/material.dart';

class WeekdayColumn extends StatelessWidget {
  final String dayLabel;
  final bool? isCompleted;
  final double width;

  const WeekdayColumn({
    super.key,
    required this.dayLabel,
    required this.isCompleted,
    this.width = 42,
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted == null 
                  ? Colors.grey 
                  : isCompleted == true
                      ? Colors.green 
                      : Colors.red,
            ),
            child: Icon(
              isCompleted == null 
                  ? Icons.remove 
                  : isCompleted == true
                      ? Icons.check 
                      : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

