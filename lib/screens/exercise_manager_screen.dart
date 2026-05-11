import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';

class ExerciseManagerScreen extends ConsumerWidget {
  const ExerciseManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exerciseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('动作管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (exercises) {
          final grouped = <String, List<Exercise>>{};
          for (final e in exercises) {
            grouped.putIfAbsent(e.category, () => []).add(e);
          }

          if (exercises.isEmpty) {
            return const Center(child: Text('暂无动作', style: TextStyle(color: Colors.grey)));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              return _CategorySection(
                category: entry.key,
                label: Exercise.categoryLabels[entry.key] ?? entry.key,
                exercises: entry.value,
                onEdit: (ex) => _showEditDialog(context, ref, ex),
                onDelete: (ex) => _confirmDelete(context, ref, ex),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    String category = 'chest';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('新建动作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '动作名称', border: OutlineInputBorder()),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
                items: Exercise.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(Exercise.categoryLabels[c] ?? c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  ref.read(exerciseProvider.notifier).addExercise(name, category);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('添加', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Exercise exercise) {
    final nameCtrl = TextEditingController(text: exercise.name);
    String category = exercise.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('编辑动作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '动作名称', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
                items: Exercise.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(Exercise.categoryLabels[c] ?? c)))
                    .toList(),
                onChanged: (v) => setState(() => category = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  ref.read(exerciseProvider.notifier).updateExercise(
                        exercise.copyWith(name: name, category: category),
                      );
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
              child: const Text('保存', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('删除动作'),
        content: Text('确定删除「${exercise.name}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              ref.read(exerciseProvider.notifier).deleteExercise(exercise.id!);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final String label;
  final List<Exercise> exercises;
  final void Function(Exercise) onEdit;
  final void Function(Exercise) onDelete;

  const _CategorySection({
    required this.category,
    required this.label,
    required this.exercises,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(label, style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
        ),
        ...exercises.map((e) => Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                title: Text(e.name, style: const TextStyle(fontSize: 15)),
                dense: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') onEdit(e);
                    if (action == 'delete') onDelete(e);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('编辑')),
                    const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
