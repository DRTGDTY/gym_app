import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/training_session.dart';
import '../models/body_weight.dart';
import '../database/dao.dart';
import '../utils/pr_calculator.dart';

class AnalysisState {
  final List<TrainingSession> recentSessions;
  final List<BodyWeight> weightHistory;
  final Map<int, List<ExerciseSet>> setsByExercise;
  final Map<int, double> best1RMs;
  final Map<int, double> prProgress; // exerciseId -> improvement%
  final bool isLoading;

  const AnalysisState({
    this.recentSessions = const [],
    this.weightHistory = const [],
    this.setsByExercise = const {},
    this.best1RMs = const {},
    this.prProgress = const {},
    this.isLoading = false,
  });

  AnalysisState copyWith({
    List<TrainingSession>? recentSessions,
    List<BodyWeight>? weightHistory,
    Map<int, List<ExerciseSet>>? setsByExercise,
    Map<int, double>? best1RMs,
    Map<int, double>? prProgress,
    bool? isLoading,
  }) =>
      AnalysisState(
        recentSessions: recentSessions ?? this.recentSessions,
        weightHistory: weightHistory ?? this.weightHistory,
        setsByExercise: setsByExercise ?? this.setsByExercise,
        best1RMs: best1RMs ?? this.best1RMs,
        prProgress: prProgress ?? this.prProgress,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final Dao _dao = Dao();

  AnalysisNotifier() : super(const AnalysisState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);

    final sessions = await _dao.getSessions(limit: 50);
    final weights = await _dao.getBodyWeights(limit: 100);
    final exercises = await _dao.getExercises();

    final Map<int, List<ExerciseSet>> setsByExercise = {};
    final Map<int, double> best1RMs = {};
    final Map<int, double> prProgress = {};

    for (final exercise in exercises) {
      if (exercise.id == null) continue;
      final history = await _dao.getHistoryForExercise(exercise.id!);
      setsByExercise[exercise.id!] = history;

      if (history.isNotEmpty) {
        final bestSet = history.reduce((a, b) =>
            PrCalculator.estimate1RM(a.weightKg, a.reps) >
                    PrCalculator.estimate1RM(b.weightKg, b.reps)
                ? a
                : b);
        best1RMs[exercise.id!] = PrCalculator.estimate1RM(bestSet.weightKg, bestSet.reps);

        // Calculate progress: compare first 10% of sets vs last 10%
        if (history.length >= 5) {
          final sorted = List<ExerciseSet>.from(history)
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          final earlyCount = (sorted.length * 0.3).ceil();
          final lateCount = (sorted.length * 0.3).ceil();
          final early = sorted.sublist(0, earlyCount);
          final late = sorted.sublist(sorted.length - lateCount);
          final earlyBest = early
              .map((s) => PrCalculator.estimate1RM(s.weightKg, s.reps))
              .reduce((a, b) => a > b ? a : b);
          final lateBest = late
              .map((s) => PrCalculator.estimate1RM(s.weightKg, s.reps))
              .reduce((a, b) => a > b ? a : b);
          if (earlyBest > 0) {
            prProgress[exercise.id!] = ((lateBest - earlyBest) / earlyBest) * 100;
          }
        }
      }
    }

    state = AnalysisState(
      recentSessions: sessions,
      weightHistory: List.from(weights.reversed),
      setsByExercise: setsByExercise,
      best1RMs: best1RMs,
      prProgress: prProgress,
      isLoading: false,
    );
  }

  double getWeeklyVolume() {
    if (state.recentSessions.isEmpty) return 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    double total = 0;
    for (final session in state.recentSessions) {
      if (session.startedAt.isAfter(weekAgo)) {
        if (session.sets != null) {
          for (final set in session.sets!) {
            total += set.volume;
          }
        }
      }
    }
    return total;
  }

  int getSessionCountThisWeek() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return state.recentSessions.where((s) => s.startedAt.isAfter(weekAgo)).length;
  }
}

final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier();
});
