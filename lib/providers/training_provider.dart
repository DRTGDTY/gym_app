import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/training_session.dart';
import '../models/exercise_set.dart';
import '../models/exercise.dart';
import '../database/dao.dart';
import '../utils/pr_calculator.dart';
import '../utils/cycle_detector.dart';

class TrainingState {
  final TrainingSession? activeSession;
  final List<ExerciseSet> currentSessionSets;
  final int currentCycleNumber;
  final Set<String> trainedCategoriesThisCycle;
  final String cycleProgressLabel;
  final bool isRestTimerRunning;

  const TrainingState({
    this.activeSession,
    this.currentSessionSets = const [],
    this.currentCycleNumber = 1,
    this.trainedCategoriesThisCycle = const {},
    this.cycleProgressLabel = '',
    this.isRestTimerRunning = false,
  });

  TrainingState copyWith({
    TrainingSession? activeSession,
    List<ExerciseSet>? currentSessionSets,
    int? currentCycleNumber,
    Set<String>? trainedCategoriesThisCycle,
    String? cycleProgressLabel,
    bool? isRestTimerRunning,
  }) =>
      TrainingState(
        activeSession: activeSession ?? this.activeSession,
        currentSessionSets: currentSessionSets ?? this.currentSessionSets,
        currentCycleNumber: currentCycleNumber ?? this.currentCycleNumber,
        trainedCategoriesThisCycle: trainedCategoriesThisCycle ?? this.trainedCategoriesThisCycle,
        cycleProgressLabel: cycleProgressLabel ?? this.cycleProgressLabel,
        isRestTimerRunning: isRestTimerRunning ?? this.isRestTimerRunning,
      );
}

class TrainingNotifier extends StateNotifier<TrainingState> {
  final Dao _dao = Dao();

  TrainingNotifier() : super(const TrainingState()) {
    _init();
  }

  Future<void> _init() async {
    final cycleNumber = await _dao.getCurrentCycleNumber();
    final trained = await _dao.getTrainedCategoriesInCycle(cycleNumber);
    final label = CycleDetector.progressLabel(trained);
    state = state.copyWith(
      currentCycleNumber: cycleNumber,
      trainedCategoriesThisCycle: trained,
      cycleProgressLabel: label,
    );
  }

  Future<void> startSession() async {
    final session = TrainingSession(cycleNumber: state.currentCycleNumber);
    final id = await _dao.insertSession(session);
    final active = session.copyWith(id: id);
    state = state.copyWith(activeSession: active, currentSessionSets: []);
  }

  Future<void> endSession() async {
    if (state.activeSession == null) return;
    final session = state.activeSession!.copyWith(endedAt: DateTime.now());
    await _dao.updateSession(session);
    state = state.copyWith(activeSession: null, currentSessionSets: []);

    // Update cycle progress
    final trained = await _dao.getTrainedCategoriesInCycle(state.currentCycleNumber);
    if (CycleDetector.shouldStartNewCycle(trained)) {
      state = state.copyWith(
        currentCycleNumber: state.currentCycleNumber + 1,
        trainedCategoriesThisCycle: {},
        cycleProgressLabel: '新 Cycle 已开始',
      );
    } else {
      final label = CycleDetector.progressLabel(trained);
      state = state.copyWith(
        trainedCategoriesThisCycle: trained,
        cycleProgressLabel: label,
      );
    }
  }

  Future<String?> addSet({required int exerciseId, required double weightKg, required int reps, double? rpe, bool isFailure = false}) async {
    if (state.activeSession == null) return null;
    final sessionId = state.activeSession!.id!;
    final nextNum = await _dao.getNextSetNumber(sessionId, exerciseId);
    final set = ExerciseSet(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: nextNum,
      weightKg: weightKg,
      reps: reps,
      rpe: rpe,
      isFailure: isFailure,
    );
    final history = await _dao.getHistoryForExercise(exerciseId);
    final prResult = PrCalculator.detectPR(set, history);
    final id = await _dao.insertExerciseSet(set);
    final savedSet = ExerciseSet(
      id: id,
      sessionId: set.sessionId,
      exerciseId: set.exerciseId,
      setNumber: set.setNumber,
      weightKg: set.weightKg,
      reps: set.reps,
      rpe: set.rpe,
      isFailure: set.isFailure,
      recordedAt: set.recordedAt,
    );
    final updatedSets = [...state.currentSessionSets, savedSet];
    state = state.copyWith(currentSessionSets: updatedSets);
    return prResult.description.isNotEmpty ? prResult.description : null;
  }

  Future<ExerciseSet?> getLastSet(int exerciseId) async {
    return await _dao.getLastSetForExercise(exerciseId);
  }

  Future<int> getNextSetNumber(int sessionId, int exerciseId) async {
    return await _dao.getNextSetNumber(sessionId, exerciseId);
  }

  List<ExerciseSet> getSetsForExercise(int exerciseId) {
    return state.currentSessionSets.where((s) => s.exerciseId == exerciseId).toList();
  }

  double getTotalVolume() {
    return state.currentSessionSets.fold(0, (sum, s) => sum + s.volume);
  }

  Set<int> getTrainedExerciseIds() {
    return state.currentSessionSets.map((s) => s.exerciseId).toSet();
  }

  Future<void> deleteSet(int id) async {
    await _dao.deleteExerciseSet(id);
    state = state.copyWith(
      currentSessionSets: state.currentSessionSets.where((s) => s.id != id).toList(),
    );
  }
}

final trainingProvider = StateNotifierProvider<TrainingNotifier, TrainingState>((ref) {
  return TrainingNotifier();
});

final recentSessionsProvider = FutureProvider<List<TrainingSession>>((ref) async {
  final dao = Dao();
  return await dao.getSessions(limit: 20);
});
