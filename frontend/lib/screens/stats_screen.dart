import 'package:flutter/material.dart';
import '../widgets/screens/task/badge.dart' as task_badge;
import '../widgets/line_chart_table.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          const SizedBox(height: 20),
            Icon(Icons.emoji_events, size: 100, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              "Prata Elite Master",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            LineChartTable(),
            const SizedBox(height: 20),
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  task_badge.Badge(
                    icon: Icons.emoji_events,
                    iconColor: Colors.green,
                    text: 'First Place',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.star,
                    iconColor: Colors.yellow,
                    text: 'Perfect Week',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.trending_up,
                    iconColor: Colors.blue,
                    text: 'Streak Master',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.fitness_center,
                    iconColor: Colors.red,
                    text: 'Goal Crusher',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.psychology,
                    iconColor: Colors.white,
                    text: 'Smart Learner',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Awards',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  task_badge.Badge(
                    icon: Icons.rocket_launch,
                    iconColor: Colors.blue,
                    text: 'Speed Demon',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.lightbulb,
                    iconColor: Colors.red,
                    text: 'Innovator',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.group,
                    iconColor: Colors.green,
                    text: 'Team Player',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.schedule,
                    iconColor: Colors.yellow,
                    text: 'Time Master',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.auto_awesome,
                    iconColor: Colors.white,
                    text: 'Excellence',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

