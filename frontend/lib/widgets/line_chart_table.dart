import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LineChartTable extends StatelessWidget {

  final Color lineColor;
  final List<FlSpot> spots;

  
  LineChartTable({
    super.key,
    Color? lineColor,
    required this.spots,
  }) : lineColor = lineColor ?? Colors.blue {
      minSpotX = spots.first.x;
      maxSpotX = spots.first.x;
      minSpotY = spots.first.y;
      maxSpotY = spots.first.y;

      for (final spot in spots) {
        if (spot.x > maxSpotX) {
          maxSpotX = spot.x;
        }

        if (spot.x < minSpotX) {
          minSpotX = spot.x;
        }

        if (spot.y > maxSpotY) {
          maxSpotY = spot.y;
        }

        if (spot.y < minSpotY) {
          minSpotY = spot.y;
        }
      }
    }

    late double minSpotX;
    late double maxSpotX;
    late double minSpotY;
    late double maxSpotY;

    Widget leftTitleWidgets(double value, TitleMeta meta) {
      final style = TextStyle(
        color: lineColor,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      );
      final intValue = value.toInt();

      if (intValue == maxSpotY) {
        return Text('', style: style);
      }

      return Text(intValue.toString(), style: style, textAlign: TextAlign.right);
    }

    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      if (value % 1 != 0) {
        return Container();
      }
      const style = TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
      return SideTitleWidget(
        meta: meta,
        child: Text(value.toInt().toString(), style: style),
      );
    }

    @override
    Widget build(BuildContext context) {
      final minSpotY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      final maxSpotY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

      return Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 20),
        child: AspectRatio(
          aspectRatio: 2,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBorderRadius: BorderRadius.zero,
                  getTooltipColor: (spot) => Colors.white,
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      return LineTooltipItem(
                        touchedSpot.y.toString(),
                        TextStyle(
                          color: touchedSpot.bar.gradient!.colors.first,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (
                  _,
                  indicators,
                ) {
                  return indicators
                      .map((int index) => const TouchedSpotIndicatorData(
                            FlLine(color: Colors.transparent),
                            FlDotData(show: false),
                          ))
                      .toList();
                },
                touchSpotThreshold: 12,
                distanceCalculator:
                    (Offset touchPoint, Offset spotPixelCoordinates) =>
                        (touchPoint - spotPixelCoordinates).distance,
              ),
              lineBarsData: [
                LineChartBarData(
                  gradient: LinearGradient(
                    colors: [
                      lineColor,
                      lineColor.withValues(alpha: 0.7),
                    ],
                  ),
                  spots: spots,
                  isCurved: true,
                  isStrokeCapRound: true,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: false,
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 8,
                        color: lineColor,
                        strokeColor: Colors.white,
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ],
              minY: minSpotY,
              maxY: maxSpotY,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: leftTitleWidgets,
                    reservedSize: 32,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: bottomTitleWidgets,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                checkToShowHorizontalLine: (value) {
                  final intValue = value.toInt();

                  if (intValue == maxSpotY.toInt()) {
                    return false;
                  }

                  return true;
                },
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(color: Colors.grey),
                  top: BorderSide(color: Colors.grey),
                  bottom: BorderSide(color: Colors.transparent),
                  right: BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }