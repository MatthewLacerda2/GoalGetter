import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../../utils/goal_storage.dart';
import '../agenda/create_task_screen.dart';
import '../../widgets/duration_handler.dart';
import '../../l10n/app_localizations.dart';
import 'roadmap/roadmap_prompt_screen.dart';

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
  static const int _maxWeeklyHours = 84;
  
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
      return AppLocalizations.of(context)!.pleaseEnterWeeklyTime;
    }
    
    final totalHours = _weeklyHours + (_weeklyMinutes / 60.0);
    if (totalHours <= 0) {
      return AppLocalizations.of(context)!.weeklyTimeMustBeGreater;
    }
    if (totalHours > _maxWeeklyHours) {
      return AppLocalizations.of(context)!.weeklyTimeCannotExceed(_maxWeeklyHours);//TODO: Not working
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
          content: Text(AppLocalizations.of(context)!.goalCreatedSuccessfully),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.createTask,
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
        title: Text(AppLocalizations.of(context)!.createNewGoal),
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
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.goalTitle,
                  hintText: AppLocalizations.of(context)!.goalTitleHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.flag),
                ),
                maxLength: 128,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterGoalTitle;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.description,
                  hintText: AppLocalizations.of(context)!.descriptionHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 128,
              ),
              const SizedBox(height: 16),
              
              // Time Commitment Section
              Text(
                AppLocalizations.of(context)!.weeklyTimeCommitment,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Weekly Duration using DurationHandler
              DurationHandler(
                onDurationChanged: _onDurationChanged,
                isRequired: true,
                validator: _validateWeeklyDuration,
              ),
              
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.youCanCreateTasksLater,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create Roadmap Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoadmapPromptScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.createRoadmap,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Create Goal Button
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
                child: Text(
                  AppLocalizations.of(context)!.create,
                  style: const TextStyle(
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