// create task screen
import 'package:flutter/material.dart';
import 'package:goal_getter/models/task.dart';
import 'package:goal_getter/utils/task_storage.dart';
import '../../widgets/screens/goals/goal_searcher.dart';
import '../../widgets/screens/tasks/days_of_the_week.dart';

class CreateTaskScreen extends StatefulWidget {
  final String? goalId;
  const CreateTaskScreen({super.key, this.goalId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  TimeOfDay? _selectedTime;
  Set<int> selectedWeekdays = {};
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (!mounted) return;
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
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startTime: _selectedTime!,
      durationMinutes: duration,
      goalId: widget.goalId,
      weekdays: selectedWeekdays.toList(),
    );
    await TaskStorage.saveNew(task);
    if (!mounted) return;
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
            // Goal Selection
            GoalSearcher(
              selectedGoalId: _selectedGoalId,
              onGoalSelected: (goal) {
                setState(() {
                  _selectedGoalId = goal?.id;
                });
              },
            ),
            const SizedBox(height: 16),
            // Time Picker
            Row(
              children: [
                const Text('Hour:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => _pickTime(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
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
            DaysOfTheWeekSelector(
              selectedWeekdays: selectedWeekdays,
              onDayToggled: (index) {
                setState(() {
                  if (selectedWeekdays.contains(index)) {
                    selectedWeekdays.remove(index);
                  } else {
                    selectedWeekdays.add(index);
                  }
                });
              },
            ),
            const Spacer(),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}