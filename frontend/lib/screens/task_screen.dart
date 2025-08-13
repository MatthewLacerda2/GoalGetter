import 'package:flutter/material.dart';
import '../widgets/screens/task/task_tab.dart';
import '../widgets/info_card.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TaskTabHeader(
            goalTitle: "Learn rook checkmates",
            streakCounter: 365,
            xpLevel: 2000,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                InfoCard(
                  title: "Make your bed",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Pray for the Lord's guidance",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Focus Blocks",
                  description: "Work in 25-minute focused sessions with 5-minute breaks to maintain high productivity throughout the day.",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Evening Review",
                  description: "Reflect on your accomplishments, plan tomorrow's priorities, and celebrate your task progress.",
                ),
                SizedBox(height: 16),
                InfoCard(
                  title: "Evening Review",
                  description: "Reflect on your accomplishments, plan tomorrow's priorities, and celebrate your task progress.",
                ),
                SizedBox(height: 16),
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