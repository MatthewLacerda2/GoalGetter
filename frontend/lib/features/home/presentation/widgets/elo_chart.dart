import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/home/debug/mock_home_screen.dart';

/// Elo progress over time for the active goal, inside a card with a 7d/30d/90d
/// range selector and a compact line chart (chess.com / lichess style).
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.yourProgress,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              _RangeSelector(
                selected: _rangeDays,
                onChanged: (v) => setState(() => _rangeDays = v),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 150,
            child: points.length < 2
                ? Center(
                    child: Text(
                      l10n.noLessonsYet,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : LineChart(_buildChartData(points)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<MockEloPoint> points) {
    final primary = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;
    final mutedText = Theme.of(context).colorScheme.onSurfaceVariant;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].elo.toDouble()),
    ];

    // Round the elo range to "nice" bounds so the Y-axis labels are tidy.
    final elos = points.map((p) => p.elo);
    final rawMin = elos.reduce((a, b) => a < b ? a : b);
    final rawMax = elos.reduce((a, b) => a > b ? a : b);
    final minY = ((rawMin - 1) / 50).floor() * 50.0;
    final maxY = ((rawMax + 1) / 50).ceil() * 50.0;
    final interval = ((maxY - minY) / 2).clamp(1, double.infinity).toDouble();

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) => FlLine(
          color: outline.withValues(alpha: 0.6),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: interval,
            getTitlesWidget: (value, meta) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 11, color: mutedText),
              ),
            ),
          ),
        ),
      ),
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
            color: primary.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

/// Compact 7d / 30d / 90d selector: a grey track with a dark selected pill.
class _RangeSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [7, 30, 90];
    return Container(
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((days) {
          final isSelected = days == selected;
          return GestureDetector(
            onTap: () => onChanged(days),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Text(
                '${days}d',
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
