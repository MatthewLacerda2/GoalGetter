// days_of_the_week.dart
import 'package:flutter/material.dart';

class DaysOfTheWeekSelector extends StatelessWidget {
  final Set<int> selectedWeekdays;
  final Function(int) onDayToggled;
  final List<String> weekdayLabels;

  const DaysOfTheWeekSelector({
    super.key,
    required this.selectedWeekdays,
    required this.onDayToggled,
    this.weekdayLabels = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Days of the week',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final isSelected = selectedWeekdays.contains(index);
            return GestureDetector(
              onTap: () => onDayToggled(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300],
                ),
                alignment: Alignment.center,
                child: Text(
                  weekdayLabels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}