import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class WeekdaySelector extends StatefulWidget {
  final void Function(int)? onChanged; // Optional callback if you want to use it elsewhere

  const WeekdaySelector({super.key, this.onChanged});

  @override
  State<WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<WeekdaySelector> {
  int _selectedDay = DateTime.now().weekday % 7; // Sunday=0, Monday=1, ..., Saturday=6

  List<String> _getDayAbbreviations(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.sunday,
      localizations.monday,
      localizations.tuesday,
      localizations.wednesday,
      localizations.thursday,
      localizations.friday,
      localizations.saturday,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDayAbbreviations(context);
    
    return Row(
      children: List.generate(7, (index) {
        final bool isSelected = index == _selectedDay;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = index;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(index);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.lightBlue[200],
                border: Border(
                  right: index < 6 ? const BorderSide(color: Colors.black, width: 1) : BorderSide.none,
                ),
              ),
              child: Center(
                child: Text(
                  days[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}