import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/body_weight.dart';
import '../database/dao.dart';
import '../utils/nutrition_calculator.dart';

class NutritionState {
  final UserProfile profile;
  final NutritionResult? result;
  final List<BodyWeight> weightHistory;
  final double? weeklyWeightChange;
  final bool showDynamicAdjustment;
  final String? adjustmentMessage;

  const NutritionState({
    required this.profile,
    this.result,
    this.weightHistory = const [],
    this.weeklyWeightChange,
    this.showDynamicAdjustment = false,
    this.adjustmentMessage,
  });

  NutritionState copyWith({
    UserProfile? profile,
    NutritionResult? result,
    List<BodyWeight>? weightHistory,
    double? weeklyWeightChange,
    bool? showDynamicAdjustment,
    String? adjustmentMessage,
  }) =>
      NutritionState(
        profile: profile ?? this.profile,
        result: result ?? this.result,
        weightHistory: weightHistory ?? this.weightHistory,
        weeklyWeightChange: weeklyWeightChange ?? this.weeklyWeightChange,
        showDynamicAdjustment: showDynamicAdjustment ?? this.showDynamicAdjustment,
        adjustmentMessage: adjustmentMessage ?? this.adjustmentMessage,
      );
}

class NutritionNotifier extends StateNotifier<NutritionState> {
  final Dao _dao = Dao();

  NutritionNotifier() : super(NutritionState(profile: UserProfile.defaultProfile())) {
    _init();
  }

  Future<void> _init() async {
    // Load saved profile if exists
    final heightStr = await _dao.getSetting('height_cm');
    final weightStr = await _dao.getSetting('weight_kg');
    final ageStr = await _dao.getSetting('age');
    final activityStr = await _dao.getSetting('activity_level');
    final goalStr = await _dao.getSetting('goal');

    UserProfile profile = UserProfile.defaultProfile();
    if (heightStr != null) {
      profile = profile.copyWith(
        heightCm: double.parse(heightStr),
        weightKg: double.parse(weightStr ?? '66.5'),
        age: int.parse(ageStr ?? '23'),
        activityLevel: _parseActivity(activityStr),
        goal: _parseGoal(goalStr),
      );
    }

    final weights = await _dao.getBodyWeights(limit: 14);
    final weeklyChange = _calcWeeklyChange(weights);

    final result = NutritionCalculator.calculate(profile);
    state = NutritionState(
      profile: profile,
      result: result,
      weightHistory: weights,
      weeklyWeightChange: weeklyChange,
    );

    // Dynamic adjustment
    if (weeklyChange != null) {
      _applyDynamicAdjustment(result.targetCalories, weeklyChange, profile.goal);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _dao.setSetting('height_cm', profile.heightCm.toString());
    await _dao.setSetting('weight_kg', profile.weightKg.toString());
    await _dao.setSetting('age', profile.age.toString());
    await _dao.setSetting('activity_level', profile.activityLevel.name);
    await _dao.setSetting('goal', profile.goal.name);

    final result = NutritionCalculator.calculate(profile);
    final weights = await _dao.getBodyWeights(limit: 14);
    final weeklyChange = _calcWeeklyChange(weights);

    state = NutritionState(
      profile: profile,
      result: result,
      weightHistory: weights,
      weeklyWeightChange: weeklyChange,
    );

    if (weeklyChange != null) {
      _applyDynamicAdjustment(result.targetCalories, weeklyChange, profile.goal);
    }
  }

  Future<void> recordWeight(double weightKg) async {
    final bw = BodyWeight(weightKg: weightKg);
    await _dao.insertBodyWeight(bw);
    final weights = await _dao.getBodyWeights(limit: 14);
    final weeklyChange = _calcWeeklyChange(weights);

    state = state.copyWith(
      weightHistory: weights,
      weeklyWeightChange: weeklyChange,
    );

    if (weeklyChange != null && state.result != null) {
      _applyDynamicAdjustment(state.result!.targetCalories, weeklyChange, state.profile.goal);
    }
  }

  void _applyDynamicAdjustment(double currentTarget, double weeklyChange, FitnessGoal goal) {
    final adjusted = NutritionCalculator.adjustCalories(currentTarget, weeklyChange, goal);
    if (adjusted != currentTarget) {
      final diff = (adjusted - currentTarget).toInt();
      final direction = diff > 0 ? '增加' : '减少';
      state = state.copyWith(
        showDynamicAdjustment: true,
        adjustmentMessage: '检测到体重变化速度偏离目标，建议${direction} ${diff.abs()} kcal/天',
      );
    }
  }

  double? _calcWeeklyChange(List<BodyWeight> weights) {
    if (weights.length < 3) return null;
    final sorted = List<BodyWeight>.from(weights)
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    // Compare average of first 3 vs last 3
    final recent = sorted.sublist(sorted.length > 6 ? sorted.length - 6 : 0);
    final firstHalf = recent.sublist(0, recent.length ~/ 2);
    final secondHalf = recent.sublist(recent.length ~/ 2);
    if (firstHalf.isEmpty || secondHalf.isEmpty) return null;
    final firstAvg = firstHalf.map((w) => w.weightKg).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.map((w) => w.weightKg).reduce((a, b) => a + b) / secondHalf.length;
    final daysDiff = secondHalf.last.recordedAt.difference(firstHalf.first.recordedAt).inDays;
    if (daysDiff <= 0) return null;
    return (secondAvg - firstAvg) / (daysDiff / 7.0); // weekly rate
  }

  ActivityLevel _parseActivity(String? name) {
    if (name == null) return ActivityLevel.moderate;
    try {
      return ActivityLevel.values.firstWhere((e) => e.name == name);
    } catch (_) {
      return ActivityLevel.moderate;
    }
  }

  FitnessGoal _parseGoal(String? name) {
    if (name == null) return FitnessGoal.bulk;
    try {
      return FitnessGoal.values.firstWhere((e) => e.name == name);
    } catch (_) {
      return FitnessGoal.bulk;
    }
  }
}

final nutritionProvider = StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier();
});
