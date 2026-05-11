import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/training_session.dart';
import '../models/exercise_set.dart';
import 'package:intl/intl.dart';

class VolumeChart extends StatelessWidget {
  final List<TrainingSession> sessions;

  const VolumeChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey))),
      );
    }

    final sorted = List<TrainingSession>.from(sessions)
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final barData = <BarChartGroupData>[];
    for (int i = 0; i < sorted.length; i++) {
      double volume = 0;
      if (sorted[i].sets != null) {
        for (final set in sorted[i].sets!) {
          volume += set.volume;
        }
      }
      barData.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: volume,
            color: const Color(0xFF4CAF50),
            width: 12,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    final maxY = barData.isEmpty
        ? 100
        : barData.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
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
                reservedSize: 50,
                getTitlesWidget: (value, meta) => Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (barData.length / 5).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                  return Text(
                    DateFormat('M/d').format(sorted[idx].startedAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 9),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          maxY: maxY,
          barGroups: barData,
        ),
      ),
    );
  }
}
