// create task screen
import 'package:flutter/material.dart';
import 'package:goal_getter/models/task.dart';
import 'package:goal_getter/utils/task_storage.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  TimeOfDay? _selectedTime;
  Set<int> selectedWeekdays = {};

  static const List<String> weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTask() async {
    final title = _titleController.text.trim();
    final duration = int.tryParse(_durationController.text.trim());
    if (title.isEmpty || _selectedTime == null || duration == null || selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.')),
      );
      return;
    }
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startTime: _selectedTime!,
      durationMinutes: duration,
      weekdays: selectedWeekdays.toList(),
    );
    await TaskStorage.saveNew(task);
    Navigator.of(context).pop(); // Go back after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            // Time Picker
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _pickTime(context),
                  child: Text(
                    _selectedTime == null
                        ? 'Pick Time'
                        : _selectedTime!.format(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Duration
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(labelText: 'Duration (minutes)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            // Weekday selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                final isSelected = selectedWeekdays.contains(index);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedWeekdays.remove(index);
                      } else {
                        selectedWeekdays.add(index);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
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
            const Spacer(),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTask,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}