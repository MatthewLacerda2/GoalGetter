import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/task_storage.dart';

class GoalProgressMeasurer extends StatelessWidget {
  const GoalProgressMeasurer({
    super.key,
    required this.hoursPerWeek,
    required this.goalId,
  });

  final double hoursPerWeek;
  final String goalId;

  Future<String> _getReservedTime() async {
    final totalMinutes = await TaskStorage.getTotalDurationForGoal(goalId);
    
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes > 0 ? '${hours}h${minutes}m' : '${hours}h';
    }
  }

  //I left this as Row because i'll eventually add another text to the side
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.timeReserved,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              FutureBuilder<String>(
                future: _getReservedTime(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? '0.0',
                    style: TextStyle(
                      fontSize: 56, // 4x bigger than the text above
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}