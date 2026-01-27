import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/fake_leaderboard_example.dart';
import '../theme/app_theme.dart';
import '../widgets/screens/stats/leaderboarder.dart';
import '../widgets/screens/stats/line_chart_table.dart';
import '../widgets/screens/stats/player_badge.dart';

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
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.edgePadding),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacing12),
              Icon(
                Icons.emoji_events,
                size: 100,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                "Prata Elite Master",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Leaderboarder(
                people: FakeLeaderboardData.getSampleData(),
                startingPosition: FakeLeaderboardData.getStartingPosition(),
                username: FakeLeaderboardData.getCurrentUsername(),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppTheme.cardRadius),
                  border: Border.all(
                    color: AppTheme.textTertiary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(
                              AppTheme.cardRadius),
                          topRight: Radius.circular(
                              AppTheme.cardRadius),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.progress,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSize20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                          AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(
                              AppTheme.cardRadius),
                          bottomRight: Radius.circular(
                              AppTheme.cardRadius),
                        ),
                      ),
                      child: LineChartTable(spots: spots),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                AppLocalizations.of(context)!.awards,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: AppTheme.spacing16),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    PlayerBadge(
                      icon: Icons.emoji_events,
                      iconColor: AppTheme.success,
                      text: 'Aprendeu todas as notas básicas',
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    PlayerBadge(
                      icon: Icons.star,
                      iconColor: AppTheme.accentSecondary,
                      text:
                          'Tocou violão até a mão não mexer mais',
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    PlayerBadge(
                      icon: Icons.trending_up,
                      iconColor: AppTheme.accentPrimary,
                      text: 'Tocou violão por 1 hora',
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    PlayerBadge(
                      icon: Icons.fitness_center,
                      iconColor: AppTheme.error,
                      text: 'Finalizou sua primeira música',
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    PlayerBadge(
                      icon: Icons.psychology,
                      iconColor: AppTheme.textPrimary,
                      text:
                          'Trocou entre três notas consecutivas',
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

