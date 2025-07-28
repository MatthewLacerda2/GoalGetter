import 'package:flutter/material.dart';

class DurationHandler extends StatefulWidget {
  final int? initialHours;
  final int? initialMinutes;
  final Function(int hours, int minutes) onDurationChanged;
  final String? label;
  final bool showLabel;
  final bool isRequired;
  final String? Function(String?)? validator;

  const DurationHandler({
    super.key,
    this.initialHours,
    this.initialMinutes,
    required this.onDurationChanged,
    this.label,
    this.showLabel = true,
    this.isRequired = false,
    this.validator,
  });

  @override
  State<DurationHandler> createState() => _DurationHandlerState();
}

class _DurationHandlerState extends State<DurationHandler> {
  late TextEditingController _hoursController;
  late TextEditingController _minutesController;
  int _hours = 0;
  int _minutes = 0;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialHours ?? 0;
    _minutes = widget.initialMinutes ?? 0;
    _hoursController = TextEditingController(text: _hours.toString());
    _minutesController = TextEditingController(text: _minutes.toString());
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _updateDuration() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    
    setState(() {
      _hours = hours;
      _minutes = minutes;
    });
    
    widget.onDurationChanged(_hours, _minutes);
  }

  String? _validateDuration(String? value) {
    if (widget.isRequired && (value == null || value.isEmpty)) {
      return 'This field is required';
    }
    
    if (value != null && value.isNotEmpty) {
      final number = int.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      if (number < 0) {
        return 'Value must be non-negative';
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  suffixText: 'h',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateDuration(),
                validator: _validateDuration,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _minutesController,
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => _updateDuration(),
                validator: (value) {
                  final baseValidation = _validateDuration(value);
                  if (baseValidation != null) return baseValidation;
                  
                  if (value != null && value.isNotEmpty) {
                    final minutes = int.tryParse(value);
                    if (minutes != null && minutes >= 60) {
                      return 'Minutes must be less than 60';
                    }
                  }
                  
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}