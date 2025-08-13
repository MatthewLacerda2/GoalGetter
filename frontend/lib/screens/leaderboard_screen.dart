import 'package:flutter/material.dart';
import '../widgets/infos_card.dart';
import '../widgets/screens/task/badge.dart' as task_badge;
import 'package:fl_chart/fl_chart.dart';

class LeaderBoardScreen extends StatelessWidget {
  const LeaderBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Division',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            InfosCard(
              texts: [
                'Lendacerda',
                'PesteNegra',
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Awards',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  task_badge.Badge(
                    icon: Icons.emoji_events,
                    text: 'First Place',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.star,
                    text: 'Perfect Week',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.trending_up,
                    text: 'Streak Master',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.fitness_center,
                    text: 'Goal Crusher',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.psychology,
                    text: 'Smart Learner',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  task_badge.Badge(
                    icon: Icons.rocket_launch,
                    text: 'Speed Demon',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.lightbulb,
                    text: 'Innovator',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.group,
                    text: 'Team Player',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.schedule,
                    text: 'Time Master',
                  ),
                  SizedBox(width: 16),
                  task_badge.Badge(
                    icon: Icons.auto_awesome,
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

