import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../../utils/goal_storage.dart';
import '../agenda/create_task_screen.dart';
import '../../widgets/duration_handler.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Duration state
  int _weeklyHours = 0;
  int _weeklyMinutes = 0;
  
  // Maximum weekly hours allowed (12 * 7 = 84 hours)
  static const double _maxWeeklyHours = 84.0;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDurationChanged(int hours, int minutes) {
    setState(() {
      _weeklyHours = hours;
      _weeklyMinutes = minutes;
    });
  }

  String? _validateWeeklyDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter weekly time commitment';
    }
    
    final totalHours = _weeklyHours + (_weeklyMinutes / 60.0);
    if (totalHours <= 0) {
      return 'Weekly time must be greater than 0';
    }
    if (totalHours > _maxWeeklyHours) {
      return 'Weekly time cannot exceed $_maxWeeklyHours hours';
    }
    
    return null;
  }

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      // Calculate total hours (including minutes)
      final totalHours = _weeklyHours + (_weeklyMinutes / 60.0);
      
      // Create Goal object
      final goal = Goal(
        id: '', // Let storage assign a UUID
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        weeklyHours: totalHours,
      );

      // Save goal to storage
      await GoalStorage.saveNew(goal);

      // Check if widget is still mounted before using context
      if (!mounted) return;

      // Show success message with action to create task
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Goal created successfully!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Create Task',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTaskScreen(goalId: goal.id),
                ),
              );
            },
          ),
        ),
      );

      Navigator.pop(context, goal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Goal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'e.g., Read a book',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                maxLength: 128,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your goal in detail...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 128,
              ),
              const SizedBox(height: 16),
              
              // Time Commitment Section
              const Text(
                'Weekly Time Commitment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // Weekly Duration using DurationHandler
              DurationHandler(
                onDurationChanged: _onDurationChanged,
                isRequired: true,
                validator: _validateWeeklyDuration,
              ),
              
              const SizedBox(height: 8),
              Text(
                'You can create tasks for this goal later',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _saveGoal,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Create',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}