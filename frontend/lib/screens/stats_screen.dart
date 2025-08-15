import 'package:flutter/material.dart';
import '../widgets/screens/task/badge.dart' as task_badge;
import '../widgets/line_chart_table.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/screens/task/leaderboarder.dart';
import '../models/leaderboard_example.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  final spots = const [
    FlSpot(0, 600),
    FlSpot(1, 650),
    FlSpot(2, 620),
    FlSpot(3, 550),
    FlSpot(4, 650),
    FlSpot(5, 700),
    FlSpot(6, 660),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
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
              Leaderboarder(
                people: LeaderboardData.getSampleData(),
                startingPosition: LeaderboardData.getStartingPosition(),
                username: LeaderboardData.getCurrentUsername(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              LineChartTable(spots: spots),
              const SizedBox(height: 16),
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

