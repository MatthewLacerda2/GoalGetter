import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../../utils/goal_storage.dart';
import '../../widgets/screens/goals/goal_progress_measurer.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key, this.goal});
  final Goal? goal;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weeklyHoursController = TextEditingController();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _weeklyHoursController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _descriptionController.text = widget.goal!.description ?? '';
      _weeklyHoursController.text = widget.goal!.weeklyHours.toString();
    }
  }

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      // Create Goal object
      final goal = Goal(
        id: widget.goal?.id ?? '', // Use existing ID if editing, otherwise empty
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        weeklyHours: double.parse(_weeklyHoursController.text),
      );

      if (widget.goal != null) {
        await GoalStorage.saveById(widget.goal!.id, goal);
      } else {
        await GoalStorage.saveNew(goal);
      }

      if (!mounted) return;

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.goal != null ? 'Goal updated successfully!' : 'Goal created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, goal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.goal != null ? widget.goal!.title : 'Create New Goal'),
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
                  hintText: 'e.g., Learn Flutter Programming',
                  border: UnderlineInputBorder(),
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
                  border: UnderlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 128,
              ),
              const SizedBox(height: 16),
              // Hours Section
              const Text(
                'Time Commitment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Weekly Hours
              TextFormField(
                controller: _weeklyHoursController,
                decoration: const InputDecoration(
                  labelText: 'Weekly Hours',
                  hintText: 'e.g., 5',
                  border: UnderlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  suffixText: 'hours/week',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weekly hours';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Weekly hours must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              GoalProgressMeasurer(
                hoursPerWeek: widget.goal?.weeklyHours ?? 0.0,
                currentWeekHours: widget.goal?.totalTaskedHours ?? 0.0,
              ),
              const SizedBox(height: 16),
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
            child: Text(
              widget.goal != null ? 'Save' : 'Create',
              style: const TextStyle(
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