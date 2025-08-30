import 'package:flutter/material.dart';
import '../widgets/screens/stats/player_badge.dart';
import '../widgets/screens/stats/line_chart_table.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/screens/stats/leaderboarder.dart';
import '../models/leaderboard_example.dart';
import '../l10n/app_localizations.dart';

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
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Icon(Icons.emoji_events, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                "Prata Elite Master",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Leaderboarder(
                people: LeaderboardData.getSampleData(),
                startingPosition: LeaderboardData.getStartingPosition(),
                username: LeaderboardData.getCurrentUsername(),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 50, 50, 50),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.progress,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 50, 50, 50),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: LineChartTable(spots: spots),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.awards,
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
                    PlayerBadge(
                      icon: Icons.emoji_events,
                      iconColor: Colors.green,
                      text: 'Aprendeu todas as notas básicas',
                    ),
                    SizedBox(width: 12),
                    PlayerBadge(
                      icon: Icons.star,
                      iconColor: Colors.yellow,
                      text: 'Tocou violão até a mão não mexer mais',
                    ),
                    SizedBox(width: 12),
                    PlayerBadge(
                      icon: Icons.trending_up,
                      iconColor: Colors.blue,
                      text: 'Tocou violão por 1 hora',
                    ),
                    SizedBox(width: 12),
                    PlayerBadge(
                      icon: Icons.fitness_center,
                      iconColor: Colors.red,
                      text: 'Finalizou sua primeira música',
                    ),
                    SizedBox(width: 12),
                    PlayerBadge(
                      icon: Icons.psychology,
                      iconColor: Colors.white,
                      text: 'Trocou entre três notas consecutivas',
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

