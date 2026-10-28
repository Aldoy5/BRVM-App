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
    final minY = prices.reduce(min) * 0.98;
    final maxY = prices.reduce(max) * 1.02;

    final spots = List.generate(
      prices.length,
      (index) => FlSpot(index.toDouble(), prices[index]),
    );

    // Jours indicatifs pour l'axe X (7 séances de bourse)
    final days = ['J-6', 'J-5', 'J-4', 'J-3', 'J-2', 'Veille', 'Auj.'];

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
                horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 3 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
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
                      if (index >= 0 && index < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[index],
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (prices.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        formatFCFA(spot.y.round()),
                        const TextStyle(
                          color: Colors.white,
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
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: chartColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) {
                      // Afficher un point uniquement sur la dernière valeur (aujourd'hui)
                      return spot.x == (prices.length - 1);
                    },
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: chartColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        chartColor.withValues(alpha: 0.20),
                        chartColor.withValues(alpha: 0.0),
                      ],
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
}
