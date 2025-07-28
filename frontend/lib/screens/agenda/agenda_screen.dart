import 'package:flutter/material.dart';
import '../../widgets/screens/goals/week.dart';
import '../../widgets/screens/tasks/task_list_widget.dart';
import '../../widgets/screens/tasks/empty_tasks_widget.dart';
import 'create_task_screen.dart';
import '../../models/task.dart';
import '../../utils/task_storage.dart';
import '../../utils/tasked_goal.dart';
import '../../l10n/app_localizations.dart';

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
      _snackBarController?.close();
      
      _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.goalNeedsTime(unassignedGoalInfo.goalTitle, unassignedGoalInfo.minutesMissing),
            style: const TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(days: 365),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.dismiss,
            textColor: Colors.white,
            onPressed: () => _snackBarController?.close(),
          ),
        ),
      );
    } else if (unassignedGoalInfo == null && _snackBarController != null) {
      _snackBarController?.close();
      _snackBarController = null;
    }
  }

  void _onTaskDeleted() {
    _loadTasks();
    _checkForUnassignedGoals();
  }

  void _onTaskEdited() {
    _loadTasks();
    _checkForUnassignedGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WeekdaySelector(onChanged: _onDayChanged),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? const EmptyTasksWidget()
                    : TaskListWidget(
                        tasks: _tasks,
                        onTaskDeleted: _onTaskDeleted,
                        onTaskEdited: _onTaskEdited,
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
              _onTaskEdited();
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
}