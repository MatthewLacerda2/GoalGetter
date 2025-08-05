import 'package:flutter/material.dart';
import 'create_goal_screen.dart';
import '../../models/goal.dart';
import '../../utils/goal_storage.dart';
import '../../widgets/screens/goals/goal_card.dart';
import '../../l10n/app_localizations.dart';

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
      case 'commited':
        goals.sort((a, b) {
          final comparison = a.weeklyHours.compareTo(b.weeklyHours);
          return isAscending ? comparison : -comparison;
        });
        break;
      case 'reserved':
        goals.sort((a, b) {
          final comparison = a.totalTaskedHours.compareTo(b.totalTaskedHours);
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Arrow indicator
                Container(
                  width: 20,
                  height: 16,
                  alignment: Alignment.center,
                  child: currentSortBy != null
                      ? Icon(
                          isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 20,
                          color: Colors.grey.shade600,
                          weight: 20,
                        )
                      : Icon(
                          Icons.arrow_downward,
                          size: 20,
                          color: Colors.grey.shade400,
                          weight: 20,
                        ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildSortButton('name', AppLocalizations.of(context)!.name),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildSortButton('commited', AppLocalizations.of(context)!.commited),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildSortButton('reserved', AppLocalizations.of(context)!.reserved),
                  ),
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
                          AppLocalizations.of(context)!.setUpYourGoals,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.createFirstGoalMessage,
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
                      return GoalCard(
                        key: Key(goal.id),
                        goal: goal,
                        index: index,
                        onDelete: () async {
                          await GoalStorage.deleteGoal(goal.id);
                          setState(() {
                            goals.removeAt(index);
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context)!.goalDeleted(goal.title)),
                                action: SnackBarAction(
                                  label: AppLocalizations.of(context)!.undo,
                                  onPressed: () async {
                                    await GoalStorage.saveNew(goal);
                                    await _loadGoals();
                                  },
                                ),
                              ),
                            );
                          }
                        },
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