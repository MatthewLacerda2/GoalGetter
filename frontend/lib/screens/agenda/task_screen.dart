// create task screen
import 'package:flutter/material.dart';
import 'package:goal_getter/models/task.dart';
import 'package:goal_getter/models/goal.dart';
import 'package:goal_getter/utils/task_storage.dart';
import 'package:goal_getter/utils/goal_storage.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
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
    _loadGoals();
    _goalSearchController.addListener(_filterGoals);
  }

  @override
  void dispose() {
    _goalSearchController.dispose();
    super.dispose();
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
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      startTime: _selectedTime!,
      durationMinutes: duration,
      goalId: _selectedGoalId,
      weekdays: selectedWeekdays.toList(),
    );
    await TaskStorage.saveNew(task);
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
            const SizedBox(height: 16),
            // Goal Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Goal (optional)', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      // Search input
                      TextField(
                        controller: _goalSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search goals...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_selectedGoalId != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: _clearGoalSelection,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              IconButton(
                                icon: Icon(
                                  _isGoalDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isGoalDropdownOpen = !_isGoalDropdownOpen;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _isGoalDropdownOpen = true;
                          });
                        },
                      ),
                      // Dropdown list
                      if (_isGoalDropdownOpen)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredGoals.length + 1, // +1 for "No goal" option
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return ListTile(
                                  dense: true,
                                  title: const Text('No goal'),
                                  onTap: _clearGoalSelection,
                                  tileColor: _selectedGoalId == null ? Colors.blue.shade50 : null,
                                );
                              }
                              final goal = _filteredGoals[index - 1];
                              final isSelected = _selectedGoalId == goal.id;
                              return ListTile(
                                dense: true,
                                title: Text(goal.title),
                                onTap: () => _selectGoal(goal),
                                tileColor: isSelected ? Colors.blue.shade50 : null,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
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
                    margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced from 6 to 4
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