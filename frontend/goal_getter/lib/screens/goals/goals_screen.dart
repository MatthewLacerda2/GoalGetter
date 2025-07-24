import 'package:flutter/material.dart';
import 'create_goal_screen.dart';
import '../../models/goal.dart';
import '../../utils/goal_storage.dart';
import 'goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal> goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final loadedGoals = await GoalStorage.loadAll();
    setState(() {
      goals = loadedGoals;
    });
  }

  String _weekdayLetter(int index) {
    const letters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return letters[index];
  }

  @override
  Widget build(BuildContext context) {
    final darkGreen = Color(0xFF206A3B);
    return Scaffold(
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first goal to get started!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero, // Remove vertical padding
              itemCount: goals.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Dismissible(
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
                  onDismissed: (direction) async {
                    await GoalStorage.deleteGoal(goal.id);
                    setState(() {
                      goals.removeAt(index);
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Goal "${goal.title}" deleted'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () async {
                              await GoalStorage.saveNew(goal);
                              await _loadGoals();
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoalScreen(goal: goal),
                        ),
                      );
                      await _loadGoals(); // Optionally reload goals if details can change
                    },
                    child: Card(
                      margin: EdgeInsets.zero, // No margin between cards
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // Rectangular, no rounded corners
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main content (title, description, days)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(goal.description),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      for (int i = 0; i < 7; i++)
                                        if (goal.selectedDays[i])
                                          Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                color: darkGreen,
                                                width: 1,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              _weekdayLetter(i),
                                              style: TextStyle(
                                                color: darkGreen,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                    ],
                                  ),
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
                                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${goal.weeklyHours}h / w',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.timeline, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${goal.totalHours}h',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
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
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
        child: SizedBox(
          width: 70,
          height: 70,
          child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateGoalScreen(),
              ),
            );
            
            if (result != null) {
              await _loadGoals(); // Reload goals from storage
            }
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