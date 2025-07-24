import 'package:flutter/material.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weeklyHoursController = TextEditingController();
  final _totalHoursController = TextEditingController();
  
  final List<bool> _selectedDays = List.filled(7, false);
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _fullWeekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _weeklyHoursController.dispose();
    _totalHoursController.dispose();
    super.dispose();
  }

  void _toggleDay(int index) {
    setState(() {
      _selectedDays[index] = !_selectedDays[index];
    });
  }

  void _saveGoal() {
    if (_formKey.currentState!.validate()) {
      // Check if at least one day is selected
      if (!_selectedDays.contains(true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one day of the week'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create goal object (you can modify this based on your data model)
      final goal = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'weeklyHours': double.parse(_weeklyHoursController.text),
        'totalHours': double.parse(_totalHoursController.text),
        'selectedDays': _selectedDays,
      };

      // TODO: Save goal to your data storage
      print('Goal created: $goal');

      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Goal created successfully!'),
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
                  hintText: 'e.g., Learn Flutter Programming',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a goal title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your goal in detail...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Hours Section
              const Text(
                'Time Commitment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Weekly Hours
              TextFormField(
                controller: _weeklyHoursController,
                decoration: const InputDecoration(
                  labelText: 'Weekly Hours',
                  hintText: 'e.g., 5',
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 16),

              // Total Hours
              TextFormField(
                controller: _totalHoursController,
                decoration: const InputDecoration(
                  labelText: 'Total Hours Goal',
                  hintText: 'e.g., 360',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timeline),
                  suffixText: 'hours total',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter total hours goal';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Total hours must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Days of the Week Section
              const Text(
                'Days of the Week',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Days Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  return GestureDetector(
                    onTap: () => _toggleDay(index),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedDays[index]
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: _selectedDays[index]
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _weekDays[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedDays[index]
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fullWeekDays[index].substring(0, 3),
                          style: TextStyle(
                            fontSize: 12,
                            color: _selectedDays[index]
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                            fontWeight: _selectedDays[index]
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
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
                    'Create Goal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}