import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';

/// Graphique d'évolution du cours avec fl_chart
class PriceChart extends StatelessWidget {
  final List<double> prices;
  final bool isGaining;

  const PriceChart({
    super.key,
    required this.prices,
    required this.isGaining,
  });

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Historique de cours non disponible',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    final chartColor = isGaining ? AppColors.gain : AppColors.loss;
    final rawMin = prices.reduce(min);
    final rawMax = prices.reduce(max);
    final minY = rawMin == rawMax ? rawMin * 0.95 : rawMin * 0.98;
    final maxY = rawMin == rawMax ? rawMax * 1.05 : rawMax * 1.02;
    final span = maxY - minY;
    final interval = span > 0 ? span / 3 : 10.0;

    final spots = List.generate(
      prices.length,
      (index) => FlSpot(index.toDouble(), prices[index]),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= prices.length) {
                        return const SizedBox.shrink();
                      }
                      final label = _getLabelForIndex(index, prices.length);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: max(1, (prices.length - 1).toDouble()),
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surface,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final price = spot.y.round();
                      final idx = spot.x.toInt();
                      final label = _getLabelForIndex(idx, prices.length);
                      return LineTooltipItem(
                        '$label : ${formatFCFA(price)}',
                        TextStyle(
                          color: chartColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: prices.length > 2,
                  curveSmoothness: 0.35,
                  color: chartColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: prices.length <= 10,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 3.5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: chartColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        chartColor.withValues(alpha: 0.25),
                        chartColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _getLabelForIndex(int index, int total) {
    if (total <= 1) return 'Auj.';
    if (total == 2) {
      return index == 0 ? 'Veille' : 'Auj.';
    }
    if (total == 3) {
      if (index == 0) return 'Veille';
      if (index == 1) return 'Ouv.';
      return 'Auj.';
    }
    if (index == total - 1) return 'Auj.';
    if (index == total - 2) return 'Veille';
    final diff = total - 1 - index;
    return 'J-$diff';
  }
}
