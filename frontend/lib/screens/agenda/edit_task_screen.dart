// edit task screen
import 'package:flutter/material.dart';
import 'package:goal_getter/models/task.dart';
import 'package:goal_getter/utils/task_storage.dart';
import '../../widgets/screens/goals/goal_searcher.dart';
import '../../widgets/screens/tasks/days_of_the_week.dart';
import '../../widgets/duration_handler.dart';
import '../../l10n/app_localizations.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _selectedTime;
  Set<int> selectedWeekdays = {};
  String? _selectedGoalId;
  int _durationHours = 0;
  int _durationMinutes = 0;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeFields() {
    _titleController.text = widget.task.title;
    _selectedTime = widget.task.startTime;
    selectedWeekdays = Set<int>.from(widget.task.weekdays);
    _selectedGoalId = widget.task.goalId;
    
    // Convert total minutes to hours and minutes
    final totalMinutes = widget.task.durationMinutes;
    _durationHours = totalMinutes ~/ 60;
    _durationMinutes = totalMinutes % 60;
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
    final totalDurationMinutes = (_durationHours * 60) + _durationMinutes;
    
    if (title.isEmpty || _selectedTime == null || totalDurationMinutes == 0 || selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillAllRequiredFields)),
      );
      return;
    }
    
    final updatedTask = Task(
      id: widget.task.id, // Keep the original ID
      title: title,
      startTime: _selectedTime!,
      durationMinutes: totalDurationMinutes,
      goalId: _selectedGoalId,
      weekdays: selectedWeekdays.toList(),
    );
    
    await TaskStorage.saveById(widget.task.id, updatedTask);
    if (!mounted) return;
    Navigator.of(context).pop(); // Go back after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.editTask)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
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
                Text(AppLocalizations.of(context)!.hour, style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
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
                        ? AppLocalizations.of(context)!.pickTime
                        : _selectedTime!.format(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Duration Handler
            DurationHandler(
              label: AppLocalizations.of(context)!.duration,
              isRequired: true,
              initialHours: _durationHours,
              initialMinutes: _durationMinutes,
              onDurationChanged: (hours, minutes) {
                setState(() {
                  _durationHours = hours;
                  _durationMinutes = minutes;
                });
              },
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
                child: Text(
                  AppLocalizations.of(context)!.save,
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