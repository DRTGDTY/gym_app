class BodyWeight {
  final int? id;
  final double weightKg;
  final DateTime recordedAt;

  BodyWeight({
    this.id,
    required this.weightKg,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'weight_kg': weightKg,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory BodyWeight.fromMap(Map<String, dynamic> map) => BodyWeight(
        id: map['id'] as int?,
        weightKg: (map['weight_kg'] as num).toDouble(),
        recordedAt: DateTime.parse(map['recorded_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'weight_kg': weightKg,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory BodyWeight.fromJson(Map<String, dynamic> json) => BodyWeight(
        id: json['id'] as int?,
        weightKg: (json['weight_kg'] as num).toDouble(),
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );
}
