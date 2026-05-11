import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../database/dao.dart';
import '../utils/export_manager.dart';
import 'exercise_manager_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('设置', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            // Training
            _sectionHeader('训练'),
            Card(
              color: const Color(0xFF1E1E1E),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.timer, color: Color(0xFF4CAF50)),
                    title: const Text('默认休息时间'),
                    subtitle: const Text('120 秒'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRestTimerSetting(context),
                  ),
                  const Divider(indent: 56, endIndent: 16, color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.fitness_center, color: Color(0xFF4CAF50)),
                    title: const Text('管理动作库'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExerciseManagerScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Data
            _sectionHeader('数据管理'),
            Card(
              color: const Color(0xFF1E1E1E),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: Colors.blue),
                    title: const Text('导出数据 (JSON)'),
                    subtitle: const Text('备份所有训练记录和动作库'),
                    onTap: () => _exportData(context),
                  ),
                  const Divider(indent: 56, endIndent: 16, color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.download, color: Colors.orange),
                    title: const Text('导入数据 (JSON)'),
                    subtitle: const Text('从备份恢复'),
                    onTap: () => _importData(context),
                  ),
                  const Divider(indent: 56, endIndent: 16, color: Colors.grey),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('清除所有数据'),
                    subtitle: const Text('此操作不可撤销'),
                    onTap: () => _confirmClearData(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // About
            _sectionHeader('关于'),
            Card(
              color: const Color(0xFF1E1E1E),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('GymApp v1.0.0'),
                subtitle: const Text('专业个人健身管理'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  void _showRestTimerSetting(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('默认休息时间'),
        content: const TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: '秒', border: OutlineInputBorder(), suffixText: 's'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('保存', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final dao = Dao();
      final exercises = await dao.getAllExercisesForExport();
      final sessions = await dao.getAllSessionsForExport();
      final weights = await dao.getBodyWeights(limit: 10000);

      final data = ExportData(
        exercises: exercises,
        sessions: sessions,
        bodyWeights: weights,
        exportedAt: DateTime.now(),
      );

      final file = await ExportManager.exportToJson(data);
      final summary = ExportManager.formatExportSize(data);

      if (context.mounted) {
        // Share or show file path
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'GymApp 数据备份 - $summary',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请通过文件管理器选择 .json 文件导入')),
    );
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('清除所有数据？'),
        content: const Text('此操作将删除所有训练记录、动作和体重数据，且无法恢复。建议先导出备份。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已清除（需重启应用）')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确认清除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
