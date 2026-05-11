enum ActivityLevel {
  sedentary('久坐不动', 1.2),
  light('轻度活动 (1-2次/周)', 1.375),
  moderate('中度活动 (3-5次/周)', 1.55),
  active('高度活动 (6-7次/周)', 1.725),
  veryActive('极高活动 (每天2次)', 1.9);

  final String label;
  final double multiplier;
  const ActivityLevel(this.label, this.multiplier);
}

enum FitnessGoal {
  bulk('增肌'),
  cut('减脂'),
  maintain('维持');

  final String label;
  const FitnessGoal(this.label);
}

class UserProfile {
  final double heightCm;
  final double weightKg;
  final int age;
  final double? bodyFatPercent;
  final ActivityLevel activityLevel;
  final FitnessGoal goal;

  const UserProfile({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    this.bodyFatPercent,
    this.activityLevel = ActivityLevel.moderate,
    this.goal = FitnessGoal.bulk,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  static UserProfile defaultProfile() => const UserProfile(
        heightCm: 177,
        weightKg: 66.5,
        age: 23,
        activityLevel: ActivityLevel.moderate,
        goal: FitnessGoal.bulk,
      );

  UserProfile copyWith({
    double? heightCm,
    double? weightKg,
    int? age,
    double? bodyFatPercent,
    ActivityLevel? activityLevel,
    FitnessGoal? goal,
  }) =>
      UserProfile(
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        age: age ?? this.age,
        bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
      );
}
