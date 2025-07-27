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
  String? currentSortBy; // null means no sorting (manual order)
  bool isAscending = true; // true for ascending, false for descending

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final loadedGoals = await GoalStorage.loadAll();
    setState(() {
      goals = loadedGoals;
      _sortGoals();
    });
  }

  void _sortGoals() {
    if (currentSortBy == null) return; // Keep manual order
    
    switch (currentSortBy) {
      case 'name':
        goals.sort((a, b) {
          final comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return isAscending ? comparison : -comparison;
        });
        break;
      case 'week':
        goals.sort((a, b) {
          final comparison = a.weeklyHours.compareTo(b.weeklyHours);
          return isAscending ? comparison : -comparison;
        });
        break;
      case 'total':
        goals.sort((a, b) {
          // Handle null totalHours (never ending goals)
          if (a.totalHours == null && b.totalHours == null) {
            return 0; // Both are never ending, maintain order
          }
          if (a.totalHours == null) {
            return isAscending ? 1 : -1; // Never ending goals go last in ascending, first in descending
          }
          if (b.totalHours == null) {
            return isAscending ? -1 : 1; // Never ending goals go last in ascending, first in descending
          }
          // Both have totalHours, compare normally
          final comparison = a.totalHours!.compareTo(b.totalHours!);
          return isAscending ? comparison : -comparison;
        });
        break;
    }
  }

  void _changeSort(String sortBy) {
    setState(() {
      if (currentSortBy == sortBy) {
        // Same button clicked - toggle ascending/descending
        isAscending = !isAscending;
      } else {
        // Different button clicked - set to ascending
        currentSortBy = sortBy;
        isAscending = true;
      }
      _sortGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sorting buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSortButton('name', 'Name'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSortButton('week', 'Week'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSortButton('total', 'Total'),
                ),
              ],
            ),
          ),
          // Goals list
          Expanded(
            child: goals.isEmpty
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
                          'Set up your Goals',
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
                : ReorderableListView.builder(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = goals.removeAt(oldIndex);
                        goals.insert(newIndex, item);
                      });
                    },
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.zero,
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return Container(
                        key: Key(goal.id),
                        child: Column(
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
                                  await _loadGoals();
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
                                                Icon(
                                                  goal.totalHours != null ? Icons.timeline : Icons.all_inclusive,
                                                  size: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 4),
                                                if (goal.totalHours != null)
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
                            ),
                            // Add divider except for the last item
                            if (index < goals.length - 1)
                              const Divider(height: 1, thickness: 1),
                          ],
                        ),
                      );
                    },
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
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGoalScreen(),
                ),
              );
              
              if (result != null) {
                await _loadGoals();
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

  Widget _buildSortButton(String sortBy, String label) {
    final isSelected = currentSortBy == sortBy;
    Color backgroundColor;
    Color foregroundColor;
    
    if (isSelected) {
      if (isAscending) {
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
      } else {
        backgroundColor = Colors.blue;
        foregroundColor = Colors.white;
      }
    } else {
      backgroundColor = Colors.white;
      foregroundColor = Colors.grey.shade700;
    }

    return ElevatedButton(
      onPressed: () => _changeSort(sortBy),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? backgroundColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }
}