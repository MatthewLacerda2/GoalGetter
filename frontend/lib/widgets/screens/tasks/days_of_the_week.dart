// days_of_the_week.dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class DaysOfTheWeekSelector extends StatelessWidget {
  final Set<int> selectedWeekdays;
  final Function(int) onDayToggled;

  const DaysOfTheWeekSelector({
    super.key,
    required this.selectedWeekdays,
    required this.onDayToggled,
  });

  List<String> _getWeekdayLabels(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final weekdays = [
      localizations.sunday,
      localizations.monday,
      localizations.tuesday,
      localizations.wednesday,
      localizations.thursday,
      localizations.friday,
      localizations.saturday,
    ];
    
    // Take the first letter of each weekday name
    return weekdays.map((day) => day[0]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final weekdayLabels = _getWeekdayLabels(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.daysOfTheWeek,
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