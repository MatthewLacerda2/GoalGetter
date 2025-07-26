import 'package:flutter/material.dart';
import '../../../models/goal.dart';
import '../../../utils/goal_storage.dart';

class GoalSearcher extends StatefulWidget {
  final String? selectedGoalId;
  final Function(Goal? goal) onGoalSelected;
  final String label;

  const GoalSearcher({
    super.key,
    this.selectedGoalId,
    required this.onGoalSelected,
    this.label = 'Goal (optional)',
  });

  @override
  State<GoalSearcher> createState() => _GoalSearcherState();
}

class _GoalSearcherState extends State<GoalSearcher> {
  final TextEditingController _goalSearchController = TextEditingController();
  List<Goal> _allGoals = [];
  List<Goal> _filteredGoals = [];
  bool _isGoalDropdownOpen = false;
  Goal? _selectedGoal;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _updateSelectedGoal();
  }

  @override
  void didUpdateWidget(GoalSearcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGoalId != widget.selectedGoalId) {
      _updateSelectedGoal();
    }
  }

  Future<void> _loadGoals() async {
    final goals = await GoalStorage.loadAll();
    setState(() {
      _allGoals = goals;
      _filteredGoals = goals;
    });
  }

  void _updateSelectedGoal() {
    if (widget.selectedGoalId != null && _allGoals.isNotEmpty) {
      _selectedGoal = _allGoals.firstWhere(
        (goal) => goal.id == widget.selectedGoalId,
        orElse: () => _allGoals.first,
      );
      _goalSearchController.text = _selectedGoal?.title ?? '';
    } else {
      _selectedGoal = null;
      _goalSearchController.text = '';
    }
  }

  void _filterGoals(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGoals = _allGoals;
      } else {
        _filteredGoals = _allGoals
            .where((goal) =>
                goal.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectGoal(Goal goal) {
    setState(() {
      _selectedGoal = goal;
      _goalSearchController.text = goal.title;
      _isGoalDropdownOpen = false;
    });
    widget.onGoalSelected(goal);
  }

  void _clearGoalSelection() {
    setState(() {
      _selectedGoal = null;
      _goalSearchController.text = '';
      _isGoalDropdownOpen = false;
    });
    widget.onGoalSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _goalSearchController,
                decoration: InputDecoration(
                  hintText: 'Search goals...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedGoal != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _clearGoalSelection,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      IconButton(
                        icon: Icon(
                          _isGoalDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isGoalDropdownOpen = !_isGoalDropdownOpen;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                onChanged: _filterGoals,
                onTap: () {
                  setState(() {
                    _isGoalDropdownOpen = true;
                  });
                },
              ),
              // Dropdown list
              if (_isGoalDropdownOpen)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredGoals.length + 1, // +1 for "No goal" option
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          dense: true,
                          title: const Text('No goal'),
                          onTap: _clearGoalSelection,
                          tileColor: _selectedGoal == null ? Colors.blue.shade50 : null,
                        );
                      }
                      final goal = _filteredGoals[index - 1];
                      final isSelected = _selectedGoal?.id == goal.id;
                      return ListTile(
                        dense: true,
                        title: Text(goal.title),
                        onTap: () => _selectGoal(goal),
                        tileColor: isSelected ? Colors.blue.shade50 : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _goalSearchController.dispose();
    super.dispose();
  }
}