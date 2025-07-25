import 'package:flutter/material.dart';
import '../../widgets/screens/goals/week.dart';
import 'create_task_screen.dart';
import '../../models/task.dart';
import '../../utils/task_storage.dart';


class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}
//TODO: we need to warn the user when there is a goal without a task
class _AgendaScreenState extends State<AgendaScreen> {
  int _selectedDay = DateTime.now().weekday % 7;
  List<Task> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
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
                    : ListView.separated(
                        itemCount: _tasks.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
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
                            },
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
                                        Text('Duration: ${task.durationMinutes} minutes', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    task.startTime.format(context),
                                    style: const TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
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