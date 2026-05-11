import 'exercise_set.dart';

class TrainingSession {
  final int? id;
  final int cycleNumber;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? notes;
  final List<ExerciseSet>? sets;

  TrainingSession({
    this.id,
    required this.cycleNumber,
    DateTime? startedAt,
    this.endedAt,
    this.notes,
    this.sets,
  }) : startedAt = startedAt ?? DateTime.now();

  Duration? get duration => endedAt != null ? endedAt!.difference(startedAt) : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'cycle_number': cycleNumber,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'notes': notes,
      };

  factory TrainingSession.fromMap(Map<String, dynamic> map) => TrainingSession(
        id: map['id'] as int?,
        cycleNumber: map['cycle_number'] as int,
        startedAt: DateTime.parse(map['started_at'] as String),
        endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
        notes: map['notes'] as String?,
      );

  TrainingSession copyWith({
    int? id,
    int? cycleNumber,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
  }) =>
      TrainingSession(
        id: id ?? this.id,
        cycleNumber: cycleNumber ?? this.cycleNumber,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cycle_number': cycleNumber,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'notes': notes,
        'sets': sets?.map((s) => s.toJson()).toList(),
      };

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
        id: json['id'] as int?,
        cycleNumber: json['cycle_number'] as int,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
        notes: json['notes'] as String?,
        sets: (json['sets'] as List<dynamic>?)
            ?.map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
