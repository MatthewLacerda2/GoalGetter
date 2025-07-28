import 'package:flutter/material.dart';
import '../../../models/task.dart';
import '../../../screens/agenda/edit_task_screen.dart';
import '../../../utils/task_storage.dart';
import '../../../l10n/app_localizations.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final String? goalTitle;
  final VoidCallback onTaskDeleted;
  final VoidCallback onTaskEdited;

  const TaskListItem({
    super.key,
    required this.task,
    this.goalTitle,
    required this.onTaskDeleted,
    required this.onTaskEdited,
  });

  TimeOfDay _calculateEndTime(TimeOfDay startTime, int durationMinutes) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = startMinutes + durationMinutes;
    final endHour = endMinutes ~/ 60;
    final endMinute = endMinutes % 60;
    return TimeOfDay(hour: endHour, minute: endMinute);
  }

  String _formatTimeRange(TimeOfDay startTime, TimeOfDay endTime) {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final endTime = _calculateEndTime(task.startTime, task.durationMinutes);
    
    return Dismissible(
      key: Key(task.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteDialog(context),
      onDismissed: (direction) => _handleTaskDeletion(context),
      child: GestureDetector(
        onTap: () => _handleTaskEdit(context),
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
                      Text(
                        task.title, 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goalTitle != null ? AppLocalizations.of(context)!.goal(goalTitle!) : ' ',
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
                    const SizedBox(height: 4),
                    Text(
                      _formatTimeRange(task.startTime, endTime),
                      style: const TextStyle(
                        fontSize: 24, 
                        color: Colors.blue, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.deleteTask),
          content: Text(
            AppLocalizations.of(context)!.areYouSureYouWantToDeleteTask(task.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTaskDeletion(BuildContext context) async {
    await TaskStorage.deleteTask(task.id);
    onTaskDeleted();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.taskDeleted(task.title)),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.undo,
            onPressed: () async {
              await TaskStorage.saveNew(task);
              onTaskDeleted(); // Refresh the list
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleTaskEdit(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
    );
    onTaskEdited();
  }
}
