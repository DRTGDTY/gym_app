import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nutrition_provider.dart';
import '../models/user_profile.dart';
import '../widgets/weight_chart.dart';
import '../widgets/stat_card.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionProvider);
    final notifier = ref.read(nutritionProvider.notifier);
    final result = state.result;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('营养管理', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),

              // Dynamic adjustment alert
              if (state.showDynamicAdjustment && state.adjustmentMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_fix_high, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.adjustmentMessage!, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),

              // Calorie targets
              if (result != null) ...[
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _calorieColumn('BMR', result.bmr, '基础代谢', Colors.grey),
                            _calorieColumn('TDEE', result.tdee, '每日消耗', const Color(0xFF4CAF50)),
                            _calorieColumn('目标', result.targetCalories, '${state.profile.goal.label}摄入', Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Macro breakdown
                Text('宏量营养分配', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _macroCard(
                        '蛋白质',
                        result.proteinG,
                        result.proteinKcal,
                        'g',
                        const Color(0xFFE57373),
                        Icons.egg,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _macroCard(
                        '碳水',
                        result.carbsG,
                        result.carbsKcal,
                        'g',
                        const Color(0xFFFFB74D),
                        Icons.grain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _macroCard(
                        '脂肪',
                        result.fatG,
                        result.fatKcal,
                        'g',
                        const Color(0xFF64B5F6),
                        Icons.water_drop,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Macro ratio bar
                if (result.targetCalories > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          Flexible(
                            flex: (result.proteinKcal / result.targetCalories * 1000).round(),
                            child: Container(color: const Color(0xFFE57373)),
                          ),
                          Flexible(
                            flex: (result.carbsKcal / result.targetCalories * 1000).round(),
                            child: Container(color: const Color(0xFFFFB74D)),
                          ),
                          Flexible(
                            flex: (result.fatKcal / result.targetCalories * 1000).round(),
                            child: Container(color: const Color(0xFF64B5F6)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('蛋白 ${(result.proteinKcal / result.targetCalories * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('碳水 ${(result.carbsKcal / result.targetCalories * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('脂肪 ${(result.fatKcal / result.targetCalories * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                // Recommendation
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.recommendation,
                            style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Record weight
              Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('记录体重', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: state.profile.weightKg.toStringAsFixed(1)),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '体重 (kg)',
                                border: OutlineInputBorder(),
                                isDense: true,
                                suffixText: 'kg',
                              ),
                              onSubmitted: (val) {
                                final w = double.tryParse(val);
                                if (w != null && w > 0) {
                                  notifier.recordWeight(w);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Use a simpler approach - just prompt
                              showDialog(
                                context: context,
                                builder: (ctx) => _WeightInputDialog(onSave: (w) => notifier.recordWeight(w)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('记录'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weight history
              if (state.weightHistory.length >= 2) ...[
                Text('体重历史', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                WeightChart(data: state.weightHistory),
                const SizedBox(height: 16),
              ],

              // Weekly weight change
              if (state.weeklyWeightChange != null) ...[
                StatCard(
                  label: '每周体重变化',
                  value: '${state.weeklyWeightChange! > 0 ? "+" : ""}${state.weeklyWeightChange!.toStringAsFixed(2)} kg',
                  subtitle: state.profile.goal == FitnessGoal.bulk
                      ? '目标: +0.25 ~ +0.5 kg/周'
                      : state.profile.goal == FitnessGoal.cut
                          ? '目标: -0.3 ~ -0.5 kg/周'
                          : '目标: 维持不变',
                  icon: Icons.trending_up,
                ),
              ],

              const SizedBox(height: 20),

              // Edit profile
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showProfileEditor(context, state.profile, notifier),
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑身体数据与目标'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calorieColumn(String label, double value, String sub, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text('kcal', style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _macroCard(String label, double grams, double kcal, String unit, Color color, IconData icon) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(grams.toStringAsFixed(0), style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(unit, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text('${kcal.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showProfileEditor(BuildContext context, UserProfile profile, NutritionNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      builder: (ctx) => _ProfileEditor(profile: profile, onSaved: (p) {
        notifier.updateProfile(p);
        Navigator.pop(ctx);
      }),
    );
  }
}

class _WeightInputDialog extends StatefulWidget {
  final void Function(double) onSave;
  const _WeightInputDialog({required this.onSave});

  @override
  State<_WeightInputDialog> createState() => _WeightInputDialogState();
}

class _WeightInputDialogState extends State<_WeightInputDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('记录体重'),
      content: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: '体重 (kg)',
          border: OutlineInputBorder(),
          suffixText: 'kg',
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            final w = double.tryParse(_ctrl.text);
            if (w != null && w > 0) {
              widget.onSave(w);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
          child: const Text('保存', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}

class _ProfileEditor extends StatefulWidget {
  final UserProfile profile;
  final void Function(UserProfile) onSaved;

  const _ProfileEditor({required this.profile, required this.onSaved});

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late double _height;
  late double _weight;
  late int _age;
  late ActivityLevel _activity;
  late FitnessGoal _goal;

  @override
  void initState() {
    super.initState();
    _height = widget.profile.heightCm;
    _weight = widget.profile.weightKg;
    _age = widget.profile.age;
    _activity = widget.profile.activityLevel;
    _goal = widget.profile.goal;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('编辑个人数据', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _height.toStringAsFixed(0)),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '身高 (cm)', border: OutlineInputBorder()),
                  onChanged: (v) => _height = double.tryParse(v) ?? _height,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _weight.toStringAsFixed(1)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '体重 (kg)', border: OutlineInputBorder()),
                  onChanged: (v) => _weight = double.tryParse(v) ?? _weight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: '$_age'),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '年龄', border: OutlineInputBorder()),
                  onChanged: (v) => _age = int.tryParse(v) ?? _age,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: const SizedBox()),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            value: _activity,
            decoration: const InputDecoration(labelText: '活动水平', border: OutlineInputBorder()),
            items: ActivityLevel.values
                .map((a) => DropdownMenuItem(value: a, child: Text(a.label, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) => setState(() => _activity = v!),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FitnessGoal>(
            value: _goal,
            decoration: const InputDecoration(labelText: '目标', border: OutlineInputBorder()),
            items: FitnessGoal.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                .toList(),
            onChanged: (v) => setState(() => _goal = v!),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSaved(UserProfile(
                  heightCm: _height,
                  weightKg: _weight,
                  age: _age,
                  activityLevel: _activity,
                  goal: _goal,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.black,
              ),
              child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
