class ExerciseSet {
  final int? id;
  final int sessionId;
  final int exerciseId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final double? rpe;
  final bool isFailure;
  final DateTime recordedAt;

  ExerciseSet({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.rpe,
    this.isFailure = false,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  double get volume => weightKg * reps;

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'rpe': rpe,
        'is_failure': isFailure ? 1 : 0,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory ExerciseSet.fromMap(Map<String, dynamic> map) => ExerciseSet(
        id: map['id'] as int?,
        sessionId: map['session_id'] as int,
        exerciseId: map['exercise_id'] as int,
        setNumber: map['set_number'] as int,
        weightKg: (map['weight_kg'] as num).toDouble(),
        reps: map['reps'] as int,
        rpe: map['rpe'] != null ? (map['rpe'] as num).toDouble() : null,
        isFailure: (map['is_failure'] as int) == 1,
        recordedAt: DateTime.parse(map['recorded_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'rpe': rpe,
        'is_failure': isFailure,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        id: json['id'] as int?,
        sessionId: json['session_id'] as int,
        exerciseId: json['exercise_id'] as int,
        setNumber: json['set_number'] as int,
        weightKg: (json['weight_kg'] as num).toDouble(),
        reps: json['reps'] as int,
        rpe: json['rpe'] != null ? (json['rpe'] as num).toDouble() : null,
        isFailure: json['is_failure'] == true,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );
}
