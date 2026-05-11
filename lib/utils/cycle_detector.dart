import '../models/exercise.dart';

class CycleDetector {
  /// Detects if a new cycle should start based on which muscle groups
  /// have been trained in the current cycle's sessions.
  ///
  /// Returns [true] if all core categories (chest, back, legs) have been
  /// covered by at least one session in the current cycle.
  static bool shouldStartNewCycle(Set<String> trainedCategoriesThisCycle) {
    for (final core in Exercise.coreCategories) {
      if (!trainedCategoriesThisCycle.contains(core)) {
        return false;
      }
    }
    return true;
  }

  /// Returns the list of core categories that still need to be trained
  /// to complete the current cycle.
  static List<String> remainingCategories(Set<String> trainedCategoriesThisCycle) {
    return Exercise.coreCategories
        .where((c) => !trainedCategoriesThisCycle.contains(c))
        .toList();
  }

  /// Returns the cycle completion percentage (0.0 to 1.0).
  static double cycleProgress(Set<String> trainedCategoriesThisCycle) {
    if (Exercise.coreCategories.isEmpty) return 1.0;
    int covered = Exercise.coreCategories.where((c) => trainedCategoriesThisCycle.contains(c)).length;
    return covered / Exercise.coreCategories.length;
  }

  /// Returns a label describing the current cycle progress.
  static String progressLabel(Set<String> trainedCategoriesThisCycle) {
    final progress = cycleProgress(trainedCategoriesThisCycle);
    if (progress >= 1.0) return 'Cycle 完成 ✓';
    final remaining = remainingCategories(trainedCategoriesThisCycle);
    final labels = remaining.map((c) => Exercise.categoryLabels[c] ?? c).toList();
    return '还需训练: ${labels.join('、')}';
  }
}
