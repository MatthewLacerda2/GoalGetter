// edit task screen
import 'package:flutter/material.dart';
import 'package:goal_getter/models/task.dart';
import 'package:goal_getter/models/goal.dart';
import 'package:goal_getter/utils/task_storage.dart';
import 'package:goal_getter/utils/goal_storage.dart';
import '../../widgets/screens/goals/goal_searcher.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;
  
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _goalSearchController = TextEditingController();
  TimeOfDay? _selectedTime;
  Set<int> selectedWeekdays = {};
  List<Goal> _goals = [];
  String? _selectedGoalId;
  bool _isGoalDropdownOpen = false;
  List<Goal> _filteredGoals = [];

  static const List<String> weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadGoals();
    _goalSearchController.addListener(_filterGoals);
  }

  @override
  void dispose() {
    _goalSearchController.dispose();
    super.dispose();
  }

  void _initializeFields() {
    // Initialize fields with existing task data
    _titleController.text = widget.task.title;
    _durationController.text = widget.task.durationMinutes.toString();
    _selectedTime = widget.task.startTime;
    selectedWeekdays = Set<int>.from(widget.task.weekdays);
    _selectedGoalId = widget.task.goalId;
    
    // Set goal search text if there's a selected goal
    if (_selectedGoalId != null) {
      _loadGoals().then((_) {
        final selectedGoal = _goals.firstWhere(
          (goal) => goal.id == _selectedGoalId,
          orElse: () => Goal(id: '', title: '', description: '', weeklyHours: 0, totalHours: 0),
        );
        if (selectedGoal.id.isNotEmpty) {
          _goalSearchController.text = selectedGoal.title;
        }
      });
    }
  }

  Future<void> _loadGoals() async {
    final goals = await GoalStorage.loadAll();
    setState(() {
      _goals = goals;
      _filteredGoals = goals;
    });
  }

  void _filterGoals() {
    final searchTerm = _goalSearchController.text.toLowerCase().trim();
    
    if (searchTerm.isEmpty) {
      setState(() {
        _filteredGoals = _goals;
      });
      return;
    }

    final matchingGoals = _goals.where((goal) => 
      goal.title.toLowerCase().contains(searchTerm)
    ).toList();

    // Sort goals: those starting with search term first, then others
    matchingGoals.sort((a, b) {
      final aStartsWith = a.title.toLowerCase().startsWith(searchTerm);
      final bStartsWith = b.title.toLowerCase().startsWith(searchTerm);
      
      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;
      return a.title.compareTo(b.title); // Alphabetical order for same type
    });

    setState(() {
      _filteredGoals = matchingGoals;
    });
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
    
    final updatedTask = Task(
      id: widget.task.id, // Keep the original ID
      title: title,
      startTime: _selectedTime!,
      durationMinutes: duration,
      goalId: _selectedGoalId,
      weekdays: selectedWeekdays.toList(),
    );
    
    await TaskStorage.saveById(widget.task.id, updatedTask);
    if (!mounted) return;
    Navigator.of(context).pop(); // Go back after saving
  }

  void _selectGoal(Goal goal) {
    setState(() {
      _selectedGoalId = goal.id;
      _goalSearchController.text = goal.title;
      _isGoalDropdownOpen = false;
    });
  }

  void _clearGoalSelection() {
    setState(() {
      _selectedGoalId = null;
      _goalSearchController.clear();
      _isGoalDropdownOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
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
                  'Save Changes',
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