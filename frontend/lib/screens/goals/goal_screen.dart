import 'package:flutter/material.dart';
import '../../models/goal.dart';
import '../../utils/goal_storage.dart';
import '../../widgets/screens/goals/goal_progress_measurer.dart';
import '../../widgets/duration_handler.dart';
import '../../l10n/app_localizations.dart';

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
  
  // Duration state
  int _weeklyHours = 0;
  int _weeklyMinutes = 0;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _titleController.text = widget.goal!.title;
      _descriptionController.text = widget.goal!.description ?? '';
      
      // Convert weekly hours to hours and minutes
      final totalHours = widget.goal!.weeklyHours;
      _weeklyHours = totalHours.floor();
      _weeklyMinutes = ((totalHours - _weeklyHours) * 60).round();
    }
  }

  void _onDurationChanged(int hours, int minutes) {
    setState(() {
      _weeklyHours = hours;
      _weeklyMinutes = minutes;
    });
  }

  String? _validateWeeklyDuration(String? value) {
    final totalHours = _weeklyHours + (_weeklyMinutes / 60.0);
    if (totalHours <= 0) {
      return AppLocalizations.of(context)!.weeklyTimeMustBeGreater;
    }
    return null;
  }

  void _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      // Calculate total hours (including minutes)
      final totalHours = _weeklyHours + (_weeklyMinutes / 60.0);
      
      // Create Goal object
      final goal = Goal(
        id: widget.goal?.id ?? '', // Use existing ID if editing, otherwise empty
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        weeklyHours: totalHours,
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
          content: Text(widget.goal != null ? AppLocalizations.of(context)!.goalUpdatedSuccessfully : AppLocalizations.of(context)!.goalCreatedSuccessfully),
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
        title: Text(widget.goal != null ? widget.goal!.title : AppLocalizations.of(context)!.createNewGoal),
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
                  border: UnderlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
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
                  border: UnderlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                maxLength: 128,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.weeklyTimeCommitment,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              DurationHandler(
                initialHours: _weeklyHours,
                initialMinutes: _weeklyMinutes,
                onDurationChanged: _onDurationChanged,
                isRequired: true,
                validator: _validateWeeklyDuration,
              ),
              
              const SizedBox(height: 12),
              GoalProgressMeasurer(
                hoursPerWeek: _weeklyHours + (_weeklyMinutes / 60.0),
                goalId: widget.goal?.id ?? '',
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
              widget.goal != null ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.create,
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