import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analysis_provider.dart';
import '../models/exercise.dart';
import '../widgets/volume_chart.dart';
import '../widgets/weight_chart.dart';
import '../widgets/stat_card.dart';
import '../utils/pr_calculator.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analysisProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('数据分析', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),

              // Session count this week
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: '本周训练',
                      value: '${state.getSessionCountThisWeek()}',
                      subtitle: '次',
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: '本周总量',
                      value: state.getWeeklyVolume() > 1000
                          ? '${(state.getWeeklyVolume() / 1000).toStringAsFixed(1)}k'
                          : state.getWeeklyVolume().toStringAsFixed(0),
                      subtitle: 'kg',
                      icon: Icons.fitness_center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Volume chart
              if (state.recentSessions.isNotEmpty) ...[
                Text('训练量趋势', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                VolumeChart(sessions: state.recentSessions),
                const SizedBox(height: 20),
              ],

              // Weight trend
              if (state.weightHistory.length >= 2) ...[
                Text('体重趋势', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                WeightChart(data: state.weightHistory),
                const SizedBox(height: 20),
              ],

              // PR records
              if (state.best1RMs.isNotEmpty) ...[
                Text('个人最佳 (估计1RM)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...state.best1RMs.entries.take(10).map((entry) {
                  final progress = state.prProgress[entry.key];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      title: Text(
                        '${entry.value.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      trailing: progress != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  progress >= 0 ? Icons.trending_up : Icons.trending_down,
                                  color: progress >= 0 ? const Color(0xFF4CAF50) : Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${progress >= 0 ? "+" : ""}${progress.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: progress >= 0 ? const Color(0xFF4CAF50) : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Recent sessions summary
              if (state.recentSessions.isNotEmpty) ...[
                Text('最近训练', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...state.recentSessions.take(10).map((session) {
                  double vol = 0;
                  if (session.sets != null) {
                    for (final s in session.sets!) {
                      vol += s.volume;
                    }
                  }
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                      title: Text(
                        'Cycle ${session.cycleNumber} — ${session.startedAt.month}/${session.startedAt.day}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        session.duration != null ? '${session.duration!.inMinutes}分钟' : '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: Text(
                        vol > 1000 ? '${(vol / 1000).toStringAsFixed(1)}k kg' : '${vol.toStringAsFixed(0)} kg',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
