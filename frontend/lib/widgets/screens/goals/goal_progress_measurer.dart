import 'package:flutter/material.dart';

class GoalProgressMeasurer extends StatelessWidget {
  const GoalProgressMeasurer({
    super.key,
    required this.hoursPerWeek,
    this.currentWeekHours = 0.0,
  });

  final double hoursPerWeek;
  final double currentWeekHours;

  String _formatExpectedTime() {
    final weeks = (currentWeekHours / hoursPerWeek).ceil();
    
    if (weeks < 4) {
      return '${weeks}w';
    } else {
      final months = weeks ~/ 4;
      final remainingWeeks = weeks % 4;
      
      if (remainingWeeks == 0) {
        return '${months}m';
      } else {
        return '${months}m${remainingWeeks}w';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if total hours are set
    final hasTotalHours = currentWeekHours > 0;
    
    return Row(
      children: [
        // Hours this week
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hours this week:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentWeekHours.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 56, // 4x bigger than the text above
                  fontWeight: FontWeight.bold,
                  color: currentWeekHours >= hoursPerWeek
                      ? Colors.blue
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // Expected time - only show if total hours are set
        if (hasTotalHours)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected time:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatExpectedTime(),
                  style: TextStyle(
                    fontSize: 56, // 4x bigger than the text above
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}