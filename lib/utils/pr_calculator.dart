import '../models/exercise_set.dart';

class PrResult {
  final bool isPr;
  final double? previousBest1RM;
  final double current1RM;
  final double? previousBestVolume;
  final double currentVolume;
  final String description;

  const PrResult({
    required this.isPr,
    this.previousBest1RM,
    required this.current1RM,
    this.previousBestVolume,
    required this.currentVolume,
    required this.description,
  });
}

class PrCalculator {
  /// Estimate 1RM using Epley formula: weight × (1 + reps/30)
  static double estimate1RMEpley(double weightKg, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weightKg;
    return weightKg * (1 + reps / 30.0);
  }

  /// Estimate 1RM using Brzycki formula: weight × 36/(37 - reps)
  /// More accurate for reps < 10
  static double estimate1RMBrzycki(double weightKg, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weightKg;
    if (reps >= 37) return weightKg * 36; // theoretical limit
    return weightKg * 36 / (37 - reps);
  }

  /// Average of Epley and Brzycki for better accuracy
  static double estimate1RM(double weightKg, int reps) {
    final epley = estimate1RMEpley(weightKg, reps);
    final brzycki = estimate1RMBrzycki(weightKg, reps);
    return (epley + brzycki) / 2.0;
  }

  /// Detect if a new set is a PR compared to historical bests
  static PrResult detectPR(ExerciseSet currentSet, List<ExerciseSet> history) {
    double current1RM = estimate1RM(currentSet.weightKg, currentSet.reps);
    double currentVolume = currentSet.volume;

    double? best1RM;
    double? bestVolume;

    if (history.isNotEmpty) {
      best1RM = history
          .map((s) => estimate1RM(s.weightKg, s.reps))
          .reduce((a, b) => a > b ? a : b);
      bestVolume = history
          .map((s) => s.volume)
          .reduce((a, b) => a > b ? a : b);
    }

    bool is1RMPr = best1RM == null || current1RM > best1RM;
    bool isVolumePr = bestVolume == null || currentVolume > bestVolume;

    String desc;
    if (is1RMPr && isVolumePr) {
      desc = 'PR! 新 1RM + 最大Volume';
    } else if (is1RMPr) {
      desc = 'PR! 新 1RM: ${current1RM.toStringAsFixed(1)} kg';
    } else if (isVolumePr) {
      desc = 'PR! 新最大Volume: ${currentVolume.toStringAsFixed(0)} kg';
    } else {
      desc = '';
    }

    return PrResult(
      isPr: is1RMPr || isVolumePr,
      previousBest1RM: best1RM,
      current1RM: current1RM,
      previousBestVolume: bestVolume,
      currentVolume: currentVolume,
      description: desc,
    );
  }
}
