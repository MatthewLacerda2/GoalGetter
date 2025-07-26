import 'package:flutter/material.dart';
import '../../widgets/screens/goals/week.dart';
import 'create_task_screen.dart';
import 'edit_task_screen.dart'; // Add this import
import '../../models/task.dart';
import '../../utils/task_storage.dart';
import '../../utils/tasked_goal.dart';
import '../../utils/goal_storage.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  int _selectedDay = DateTime.now().weekday % 7;
  List<Task> _tasks = [];
  bool _loading = true;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBarController;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _checkForUnassignedGoals();
  }

  @override
  void dispose() {
    _snackBarController?.close();
    super.dispose();
  }

  void _onDayChanged(int day) {
    setState(() {
      _selectedDay = day;
      _loading = true;
    });
    _loadTasks(day: day);
  }

  Future<void> _loadTasks({int? day}) async {
    final weekday = day ?? _selectedDay;
    final tasks = await TaskStorage.loadByDay(weekday);
    tasks.sort((a, b) => a.startTime.hour != b.startTime.hour
        ? a.startTime.hour.compareTo(b.startTime.hour)
        : a.startTime.minute.compareTo(b.startTime.minute));
    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  Future<void> _checkForUnassignedGoals() async {
    final unassignedGoalInfo = await findUnassignedGoal();
    
    if (unassignedGoalInfo != null && mounted) {
      // Close any existing snackbar
      _snackBarController?.close();
      
      // Show persistent snackbar
      _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${unassignedGoalInfo.goalTitle} needs ${unassignedGoalInfo.minutesMissing} more minutes per week',
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(days: 365), // Very long duration to make it persistent
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              _snackBarController?.close();
            },
          ),
        ),
      );
    } else if (unassignedGoalInfo == null && _snackBarController != null) {
      // If no unassigned goals, close the snackbar
      _snackBarController?.close();
      _snackBarController = null;
    }
  }

  // Helper method to calculate end time
  TimeOfDay _calculateEndTime(TimeOfDay startTime, int durationMinutes) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = startMinutes + durationMinutes;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;
    return TimeOfDay(hour: endHour, minute: endMinute);
  }

  // Helper method to format time range
  String _formatTimeRange(TimeOfDay startTime, TimeOfDay endTime) {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WeekdaySelector(
            onChanged: _onDayChanged,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No activities for the day (yet)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _loadTasksWithGoals(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final tasksWithGoals = snapshot.data ?? [];
                          
                          return ListView.separated(
                            itemCount: tasksWithGoals.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final taskData = tasksWithGoals[index];
                              final task = taskData['task'] as Task;
                              final goalTitle = taskData['goalTitle'] as String?;
                              final endTime = _calculateEndTime(task.startTime, task.durationMinutes);
                              
                              return Dismissible(
                                key: Key(task.id),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Delete Task'),
                                        content: Text(
                                          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                onDismissed: (direction) async {
                                  await TaskStorage.deleteTask(task.id);
                                  setState(() {
                                    _tasks.removeAt(index);
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Task "${task.title}" deleted'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () async {
                                            await TaskStorage.saveNew(task);
                                            await _loadTasks();
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                  // Check for unassigned goals after task deletion
                                  _checkForUnassignedGoals();
                                },
                                child: GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTaskScreen(task: task),
                                      ),
                                    );
                                    // Refresh tasks when returning from edit task screen
                                    _loadTasks();
                                    // Check for unassigned goals after editing a task
                                    _checkForUnassignedGoals();
                                  },
                                  child: Container(
                                    color: Colors.grey.shade100,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  goalTitle != null ? 'Goal: $goalTitle' : ' ',
                                                  style: TextStyle(
                                                    fontSize: 14, 
                                                    color: goalTitle != null ? Colors.orange : Colors.transparent,
                                                    fontWeight: goalTitle != null ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const SizedBox(height: 4), // Align with space between title and goal
                                              Text(
                                                _formatTimeRange(task.startTime, endTime),
                                                style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
        child: SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
              );
              // Refresh tasks when returning from create task screen
              _loadTasks();
              // Check for unassigned goals after creating a task
              _checkForUnassignedGoals();
            },
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            mini: false,
            child: const Icon(Icons.add, size: 48)
          ),
        ),
      ),
    );
  }

  // Helper method to load tasks with their associated goal titles
  Future<List<Map<String, dynamic>>> _loadTasksWithGoals() async {
    final List<Map<String, dynamic>> result = [];
    
    for (final task in _tasks) {
      String? goalTitle;
      if (task.goalId != null) {
        final goal = await GoalStorage.loadById(task.goalId!);
        goalTitle = goal?.title;
      }
      
      result.add({
        'task': task,
        'goalTitle': goalTitle,
      });
    }
    
    return result;
  }
}