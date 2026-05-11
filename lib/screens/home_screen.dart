import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_provider.dart';
import '../providers/analysis_provider.dart';
import '../providers/nutrition_provider.dart';
import '../models/exercise.dart';
import '../utils/cycle_detector.dart';
import '../widgets/stat_card.dart';
import '../widgets/weight_chart.dart';
import 'active_training_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainingState = ref.watch(trainingProvider);
    final analysisState = ref.watch(analysisProvider);
    final nutritionState = ref.watch(nutritionProvider);

    final sessionCount = analysisState.getSessionCountThisWeek();
    final weeklyVolume = analysisState.getWeeklyVolume();
    final cycleProgress = CycleDetector.cycleProgress(trainingState.trainedCategoriesThisCycle);
    final isInSession = trainingState.activeSession != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GymApp', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Cycle ${trainingState.currentCycleNumber}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (nutritionState.result != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${nutritionState.result!.targetCalories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Cycle Progress
              Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('当前 Cycle 进度', style: Theme.of(context).textTheme.labelLarge),
                          Text(
                            '${(cycleProgress * 100).toInt()}%',
                            style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cycleProgress,
                          minHeight: 6,
                          backgroundColor: Colors.grey[800],
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trainingState.cycleProgressLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: '本周训练',
                      value: '$sessionCount',
                      subtitle: '次',
                      icon: Icons.fitness_center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: '本周总量',
                      value: weeklyVolume > 1000
                          ? '${(weeklyVolume / 1000).toStringAsFixed(1)}k'
                          : weeklyVolume.toStringAsFixed(0),
                      subtitle: 'kg',
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: '当前体重',
                      value: nutritionState.weightHistory.isNotEmpty
                          ? nutritionState.weightHistory.first.weightKg.toStringAsFixed(1)
                          : '66.5',
                      subtitle: 'kg',
                      icon: Icons.monitor_weight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'BMR',
                      value: nutritionState.result != null
                          ? nutritionState.result!.bmr.toStringAsFixed(0)
                          : '1661',
                      subtitle: 'kcal/天',
                      icon: Icons.local_fire_department,
                      accentColor: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weight Chart
              if (nutritionState.weightHistory.length >= 2) ...[
                Text('体重趋势', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                WeightChart(data: nutritionState.weightHistory),
                const SizedBox(height: 20),
              ],

              // Start Training Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isInSession
                      ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTrainingScreen()))
                      : () async {
                          final trainingNotifier = ref.read(trainingProvider.notifier);
                          await trainingNotifier.startSession();
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveTrainingScreen()));
                          }
                        },
                  icon: Icon(isInSession ? Icons.play_circle : Icons.add_circle, size: 28),
                  label: Text(
                    isInSession ? '继续训练' : '开始训练',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
