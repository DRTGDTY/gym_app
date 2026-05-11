import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/training_session.dart';
import '../models/body_weight.dart';

class ExportData {
  final List<Exercise> exercises;
  final List<TrainingSession> sessions;
  final List<BodyWeight> bodyWeights;
  final DateTime exportedAt;

  const ExportData({
    required this.exercises,
    required this.sessions,
    required this.bodyWeights,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() => {
        'version': '1.0',
        'exported_at': exportedAt.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'body_weights': bodyWeights.map((w) => w.toJson()).toList(),
      };

  factory ExportData.fromJson(Map<String, dynamic> json) => ExportData(
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        sessions: (json['sessions'] as List<dynamic>)
            .map((s) => TrainingSession.fromJson(s as Map<String, dynamic>))
            .toList(),
        bodyWeights: (json['body_weights'] as List<dynamic>)
            .map((w) => BodyWeight.fromJson(w as Map<String, dynamic>))
            .toList(),
        exportedAt: DateTime.parse(json['exported_at'] as String),
      );
}

class ExportManager {
  static Future<File> exportToJson(ExportData data) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final file = File('${dir.path}/gym_app_backup_$timestamp.json');
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data.toJson());
    await file.writeAsString(jsonStr);
    return file;
  }

  static Future<ExportData> importFromJson(File file) async {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return ExportData.fromJson(json);
  }

  static String formatExportSize(ExportData data) {
    final json = data.toJson();
    return '${json['exercises']?.length ?? 0} 个动作, '
        '${json['sessions']?.length ?? 0} 次训练, '
        '${json['body_weights']?.length ?? 0} 条体重记录';
  }
}
