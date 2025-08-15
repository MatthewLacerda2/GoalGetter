import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LineChartWidget extends StatelessWidget {
  LineChartWidget({
    super.key,
    Color? lineColor,
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

  final Color lineColor;

  final spots = const [
    FlSpot(0, 3.5),
    FlSpot(1, 2.5),
    FlSpot(2, 1.5),
    FlSpot(3, 2.0),
    FlSpot(4, 2.5),
    FlSpot(5, 2.0),
    FlSpot(6, 1.0),
  ];

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
    final intValue = reverseY(value, minSpotY, maxSpotY).toInt();

    if (intValue == (maxSpotY + minSpotY)) {
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
    return Padding(
      padding: const EdgeInsets.only(right: 22, bottom: 20),
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
                    lineColor.withOpacity(0.7),
                  ],
                ),
                spots: reverseSpots(spots, minSpotY, maxSpotY),
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
            minY: 0,
            maxY: maxSpotY + minSpotY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: leftTitleWidgets,
                  reservedSize: 38,
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
                final intValue = reverseY(value, minSpotY, maxSpotY).toInt();

                if (intValue == (maxSpotY + minSpotY).toInt()) {
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

  double reverseY(double y, double minX, double maxX) {
    return (maxX + minX) - y;
  }

  List<FlSpot> reverseSpots(List<FlSpot> inputSpots, double minY, double maxY) {
    return inputSpots.map((spot) {
      return spot.copyWith(y: (maxY + minY) - spot.y);
    }).toList();
  }
}