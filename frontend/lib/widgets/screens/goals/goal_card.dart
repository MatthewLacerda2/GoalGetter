import 'package:flutter/material.dart';
import '../../../models/goal.dart';
import '../../../screens/goals/goal_screen.dart';
import '../../../utils/task_storage.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final int index;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Dismissible(
          key: Key(goal.id),
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
                  title: const Text('Delete Goal'),
                  content: Text(
                    'Are you sure you want to delete "${goal.title}"? This action cannot be undone.',
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
          onDismissed: (direction) => onDelete(),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GoalScreen(goal: goal),
                ),
              );
              // Optionally: callback to reload goals
            },
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle on the left
                    ReorderableDragStartListener(
                      index: index,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.drag_handle,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                    // Main content (title, description, days)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(goal.description ?? ''),
                        ],
                      ),
                    ),
                    // Hours info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Commited: ${goal.weeklyHours}h/w',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        FutureBuilder<int>(
                          future: TaskStorage.getTotalDurationForGoal(goal.id),
                          builder: (context, snapshot) {
                            final totalMinutes = snapshot.data ?? 0;
                            final totalHours = (totalMinutes / 60).toStringAsFixed(1);
                            final isOvercommitted = double.parse(totalHours) >= goal.weeklyHours;
                            return Text(
                              'Reserved: ${totalHours}h',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOvercommitted ? Colors.lightBlueAccent : Colors.grey.shade600,
                                fontWeight: isOvercommitted ? FontWeight.bold : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Add divider except for the last item (optional: handle outside)
      ],
    );
  }
}