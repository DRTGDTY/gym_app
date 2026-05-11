import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/body_weight.dart';
import 'package:intl/intl.dart';

class WeightChart extends StatelessWidget {
  final List<BodyWeight> data;

  const WeightChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey))),
      );
    }

    final sorted = List<BodyWeight>.from(data)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final spots = sorted.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.weightKg,
      );
    }).toList();

    final minY = sorted.map((w) => w.weightKg).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = sorted.map((w) => w.weightKg).reduce((a, b) => a > b ? a : b) + 1;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[800]!,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (spots.length / 4).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                  return Text(
                    DateFormat('M/d').format(sorted[idx].recordedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF4CAF50),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF4CAF50).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
