import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/stock_models.dart';
import '../constants.dart';

class StockChart extends StatelessWidget {
  final List<CandleData> candleData;
  final String symbol;
  final bool isPositive;

  const StockChart({
    super.key,
    required this.candleData,
    required this.symbol,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    if (candleData.isEmpty) {
      return Container(
        height: 200,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateInterval(),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: candleData.length / 4,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < candleData.length) {
                    final date = candleData[index].timestamp;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        '${date.month}/${date.day}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          minX: 0,
          maxX: candleData.length.toDouble() - 1,
          minY: candleData.map((c) => c.low).reduce((a, b) => a < b ? a : b),
          maxY: candleData.map((c) => c.high).reduce((a, b) => a > b ? a : b),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < candleData.length; i++)
                  FlSpot(i.toDouble(), candleData[i].close),
              ],
              isCurved: true,
              color: isPositive ? Colors.green : Colors.red,
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateInterval() {
    if (candleData.length < 8) return 1;
    return candleData.length / 4;
  }
}
