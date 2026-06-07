import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/home/debug/mock_home_screen.dart';

/// Elo progress over time for the active goal, with 7 / 30 / 90-day filter tabs
/// above the line chart (chess.com / lichess rating-graph style).
class EloChart extends StatefulWidget {
  final List<MockEloPoint> history;

  const EloChart({super.key, required this.history});

  @override
  State<EloChart> createState() => _EloChartState();
}

class _EloChartState extends State<EloChart> {
  int _rangeDays = 30;

  List<MockEloPoint> get _visiblePoints {
    if (widget.history.length <= _rangeDays) return widget.history;
    return widget.history.sublist(widget.history.length - _rangeDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = _visiblePoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourProgress,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 7, label: Text(l10n.last7Days)),
            ButtonSegment(value: 30, label: Text(l10n.last30Days)),
            ButtonSegment(value: 90, label: Text(l10n.last90Days)),
          ],
          selected: {_rangeDays},
          showSelectedIcon: false,
          onSelectionChanged: (selection) {
            setState(() => _rangeDays = selection.first);
          },
        ),
        const SizedBox(height: 16.0),
        SizedBox(
          height: 200,
          child: points.length < 2
              ? Center(
                  child: Text(
                    l10n.noLessonsYet,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : LineChart(_buildChartData(points)),
        ),
      ],
    );
  }

  LineChartData _buildChartData(List<MockEloPoint> points) {
    final primary = Theme.of(context).colorScheme.primary;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].elo.toDouble()),
    ];

    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touched) => touched
              .map((t) => LineTooltipItem(
                    '${t.y.toInt()}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ))
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: primary,
          barWidth: 3,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: primary.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
