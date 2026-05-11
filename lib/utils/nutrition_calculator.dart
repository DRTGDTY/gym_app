import '../models/user_profile.dart';

class NutritionResult {
  final double bmr;
  final double tdee;
  final double targetCalories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double proteinKcal;
  final double fatKcal;
  final double carbsKcal;
  final String recommendation;

  const NutritionResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.proteinKcal,
    required this.fatKcal,
    required this.carbsKcal,
    required this.recommendation,
  });
}

class NutritionCalculator {
  static NutritionResult calculate(UserProfile profile) {
    final bmr = _calcBMR(profile);
    final tdee = _calcTDEE(bmr, profile.activityLevel);
    final targetCalories = _calcTarget(tdee, profile.goal);
    final proteinG = _calcProtein(profile.weightKg, profile.goal);
    final fatG = _calcFat(profile.weightKg);
    final remainingKcal = targetCalories - (proteinG * 4) - (fatG * 9);
    final carbsG = remainingKcal > 0 ? remainingKcal / 4 : 0.0;

    String recommendation;
    switch (profile.goal) {
      case FitnessGoal.bulk:
        recommendation = '增肌期：保持热量盈余，每周目标增重 0.25-0.5kg。'
            '若体重增长过快(>0.5kg/周)则自动减少 150kcal，'
            '若增重不足(<0.15kg/周)则自动增加 150kcal。';
        break;
      case FitnessGoal.cut:
        recommendation = '减脂期：保持热量赤字，每周目标减重 0.3-0.5kg。'
            '蛋白质摄入提高至 2.2g/kg 以最大限度保留肌肉。'
            '若减重过快(>0.7kg/周)则自动增加 150kcal。';
        break;
      case FitnessGoal.maintain:
        recommendation = '维持期：保持当前体重，蛋白质 1.6g/kg 维持肌肉量。';
        break;
    }

    return NutritionResult(
      bmr: bmr,
      tdee: tdee,
      targetCalories: targetCalories,
      proteinG: proteinG,
      fatG: fatG,
      carbsG: carbsG,
      proteinKcal: proteinG * 4,
      fatKcal: fatG * 9,
      carbsKcal: carbsG * 4,
      recommendation: recommendation,
    );
  }

  static double _calcBMR(UserProfile profile) {
    return 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age + 5;
  }

  static double _calcTDEE(double bmr, ActivityLevel level) {
    return bmr * level.multiplier;
  }

  static double _calcTarget(double tdee, FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.bulk:
        return tdee + 350;
      case FitnessGoal.cut:
        return tdee - 350;
      case FitnessGoal.maintain:
        return tdee;
    }
  }

  static double _calcProtein(double weightKg, FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.bulk:
        return weightKg * 2.0;
      case FitnessGoal.cut:
        return weightKg * 2.2;
      case FitnessGoal.maintain:
        return weightKg * 1.6;
    }
  }

  static double _calcFat(double weightKg) {
    return weightKg * 0.9;
  }

  static double adjustCalories(double currentTarget, double weeklyWeightChange, FitnessGoal goal) {
    const adjustment = 150.0;
    switch (goal) {
      case FitnessGoal.bulk:
        if (weeklyWeightChange > 0.5) return currentTarget - adjustment;
        if (weeklyWeightChange < 0.15) return currentTarget + adjustment;
        break;
      case FitnessGoal.cut:
        if (weeklyWeightChange < -0.7) return currentTarget + adjustment;
        if (weeklyWeightChange > -0.2) return currentTarget - adjustment;
        break;
      case FitnessGoal.maintain:
        if (weeklyWeightChange.abs() > 0.3) {
          return weeklyWeightChange > 0 ? currentTarget - adjustment : currentTarget + adjustment;
        }
        break;
    }
    return currentTarget;
  }
}
