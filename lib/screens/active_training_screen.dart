import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_provider.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise_set.dart';
import '../models/exercise.dart';
import '../widgets/rest_timer.dart';
import '../widgets/pr_badge.dart';

class ActiveTrainingScreen extends ConsumerStatefulWidget {
  const ActiveTrainingScreen({super.key});

  @override
  ConsumerState<ActiveTrainingScreen> createState() => _ActiveTrainingScreenState();
}

class _ActiveTrainingScreenState extends ConsumerState<ActiveTrainingScreen> {
  int? _selectedExerciseId;
  String? _prMessage;

  @override
  Widget build(BuildContext context) {
    final trainingState = ref.watch(trainingProvider);
    final exercisesAsync = ref.watch(exerciseProvider);

    if (trainingState.activeSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('训练中')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('没有活跃的训练'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(trainingProvider.notifier).startSession();
                },
                child: const Text('开始训练'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('训练中 — Cycle ${trainingState.currentCycleNumber}'),
        actions: [
          TextButton.icon(
            onPressed: () => _endSession(),
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            label: const Text('结束', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Session stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                _statChip('组数', '${trainingState.currentSessionSets.length}'),
                const SizedBox(width: 16),
                _statChip('总量', '${trainingState.getTotalVolume().toStringAsFixed(0)} kg'),
                const SizedBox(width: 16),
                _statChip('动作', '${trainingState.getTrainedExerciseIds().length}'),
              ],
            ),
          ),

          // PR message
          if (_prMessage != null) PrBadge(message: _prMessage!),

          // Exercise selection + sets
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (exercises) {
                final grouped = _groupByCategory(exercises);
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Exercise selector
                    ...grouped.entries.map((entry) => _buildCategorySection(entry.key, entry.value)),
                    if (_selectedExerciseId != null) ...[
                      const Divider(height: 32),
                      _buildSetInput(exercises),
                    ],
                  ],
                );
              },
            ),
          ),

          // Rest timer
          RestTimer(
            defaultSeconds: 120,
            onComplete: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('休息时间到！'), duration: Duration(seconds: 1)),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Map<String, List<Exercise>> _groupByCategory(List<Exercise> exercises) {
    final map = <String, List<Exercise>>{};
    for (final e in exercises) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    return map;
  }

  Widget _buildCategorySection(String category, List<Exercise> exercises) {
    final label = Exercise.categoryLabels[category] ?? category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: exercises.map((e) {
            final isSelected = _selectedExerciseId == e.id;
            return ChoiceChip(
              label: Text(e.name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedExerciseId = selected ? e.id : null;
                  _prMessage = null;
                });
              },
              selectedColor: const Color(0xFF4CAF50),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 13,
              ),
              backgroundColor: const Color(0xFF2A2A2A),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSetInput(List<Exercise> exercises) {
    final exercise = exercises.firstWhere((e) => e.id == _selectedExerciseId);
    final sessionSets = ref.read(trainingProvider).currentSessionSets;
    final exerciseSets = sessionSets.where((s) => s.exerciseId == _selectedExerciseId).toList();

    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(exercise.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('第 ${exerciseSets.length + 1} 组'),
              ],
            ),
            const SizedBox(height: 12),

            // Previous sets summary
            if (exerciseSets.isNotEmpty) ...[
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: exerciseSets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = exerciseSets[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF333333),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${s.weightKg.toStringAsFixed(1)}kg × ${s.reps}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Input form
            _SetInputForm(
              exercise: exercise,
              onSaved: (weight, reps, rpe, isFailure) async {
                final notifier = ref.read(trainingProvider.notifier);
                final prMsg = await notifier.addSet(
                  exerciseId: exercise.id!,
                  weightKg: weight,
                  reps: reps,
                  rpe: rpe,
                  isFailure: isFailure,
                );
                setState(() {
                  if (prMsg != null && prMsg!.isNotEmpty) {
                    _prMessage = prMsg;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('结束训练？'),
        content: Text('当前已记录 ${ref.read(trainingProvider).currentSessionSets.length} 组'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('继续训练')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('结束', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(trainingProvider.notifier).endSession();
      if (mounted) Navigator.pop(context);
    }
  }
}

class _SetInputForm extends StatefulWidget {
  final Exercise exercise;
  final void Function(double weight, int reps, double? rpe, bool isFailure) onSaved;

  const _SetInputForm({required this.exercise, required this.onSaved});

  @override
  State<_SetInputForm> createState() => _SetInputFormState();
}

class _SetInputFormState extends State<_SetInputForm> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  double? _rpe;
  bool _isFailure = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill last weight
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastWeight();
    });
  }

  Future<void> _loadLastWeight() async {
    // Access via context - in real app use provider
    final weightStr = _weightCtrl.text;
    if (weightStr.isEmpty) {
      _weightCtrl.text = '20.0'; // default placeholder
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '重量 (kg)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _repsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '次数',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // RPE selector
        Row(
          children: [
            const Text('RPE: ', style: TextStyle(color: Colors.grey)),
            ...List.generate(5, (i) {
              final val = (i + 6).toDouble();
              final isSelected = _rpe == val;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _rpe = isSelected ? null : val),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(val.toStringAsFixed(0), style: const TextStyle(fontSize: 12)),
                  ),
                ),
              );
            }),
            const Spacer(),
            Row(
              children: [
                const Text('力竭', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Switch(
                  value: _isFailure,
                  onChanged: (v) => setState(() => _isFailure = v),
                  activeColor: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSet,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('记录本组', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  void _saveSet() {
    final weight = double.tryParse(_weightCtrl.text);
    final reps = int.tryParse(_repsCtrl.text);
    if (weight == null || reps == null || weight <= 0 || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的重量和次数')),
      );
      return;
    }
    widget.onSaved(weight, reps, _rpe, _isFailure);

    // Reset form
    _repsCtrl.clear();
    _rpe = null;
    _isFailure = false;
    // Keep weight for next set
  }
}
