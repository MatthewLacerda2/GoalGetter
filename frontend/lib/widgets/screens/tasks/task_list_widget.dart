import 'package:flutter/material.dart';
import '../../../models/task.dart';
import '../../../utils/goal_storage.dart';
import 'task_list_item.dart';

class TaskListWidget extends StatelessWidget {
  final List<Task> tasks;
  final VoidCallback onTaskDeleted;
  final VoidCallback onTaskEdited;

  const TaskListWidget({
    super.key,
    required this.tasks,
    required this.onTaskDeleted,
    required this.onTaskEdited,
  });

  Future<List<Map<String, dynamic>>> _loadTasksWithGoals() async {
    final List<Map<String, dynamic>> result = [];
    
    for (final task in tasks) {
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
            
            return TaskListItem(
              task: task,
              goalTitle: goalTitle,
              onTaskDeleted: onTaskDeleted,
              onTaskEdited: onTaskEdited,
            );
          },
        );
      },
    );
  }
} 