import 'package:flutter/material.dart';
import 'package:goal_getter/widgets/screens/task/task_test_button.dart';
import '../widgets/screens/task/task_tab_header.dart';
import '../widgets/info_card.dart';
import '../widgets/progress_bar.dart';
import '../widgets/infos_card.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TaskTabHeader(
            xpLevel: 2000,
            goalTitle: "Learn rook checkmates",
            streakCounter: 365,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SizedBox(height: 10),
                ProgressBar(
                  title: "Make your bed",
                  icon: Icons.task_alt,
                  progress: 35,
                  end: 100,
                  color: Colors.green,
                ),
                SizedBox(height: 28),
                LessonButton(
                  title: "Learn session",
                  buttonText: "Show me what you got",
                  onPressed: () {
                    // TODO: Implement button action
                  },
                ),
                SizedBox(height: 20),
                Text(
                  "Notes:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 14),
                InfosCard(
                  texts: [
                    "First text item",
                    "Second text item", 
                    "Third text item",
                  ],
                ),
                SizedBox(height: 20),
                InfoCard(
                  title: "Focus Blocks",
                  description: "Work in 25-minute focused sessions with 5-minute breaks to maintain high productivity throughout the day.",
                ),
                SizedBox(height: 20),
                InfoCard(
                  title: "Evening Review",
                  description: "Reflect on your accomplishments, plan tomorrow's priorities, and celebrate your task progress.",
                ),
                SizedBox(height: 20),
                InfoCard(
                  title: "Evening Review",
                  description: "Reflect on your accomplishments, plan tomorrow's priorities, and celebrate your task progress.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}