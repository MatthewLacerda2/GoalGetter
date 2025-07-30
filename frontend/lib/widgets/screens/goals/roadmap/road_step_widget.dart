// roadmap steps
import 'package:flutter/material.dart';
import '../../../../utils/road_step_data.dart';

class RoadStepWidget extends StatelessWidget {
  final RoadStepData roadStep;

  const RoadStepWidget({
    super.key,
    required this.roadStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title box with thick outline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 3.0, // Thick outline
            ),
          ),
          child: Text(
            roadStep.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Description box with thin outline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
              width: 1.0, // Thin outline
            ),
          ),
          child: Text(
            roadStep.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}