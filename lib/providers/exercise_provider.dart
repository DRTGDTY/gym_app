import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../database/dao.dart';

class ExerciseNotifier extends StateNotifier<AsyncValue<List<Exercise>>> {
  final Dao _dao = Dao();

  ExerciseNotifier() : super(const AsyncValue.loading()) {
    loadExercises();
  }

  Future<void> loadExercises({String? category}) async {
    state = const AsyncValue.loading();
    try {
      final exercises = await _dao.getExercises(category: category);
      state = AsyncValue.data(exercises);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExercise(String name, String category) async {
    final exercise = Exercise(name: name, category: category);
    await _dao.insertExercise(exercise);
    await loadExercises();
  }

  Future<void> updateExercise(Exercise exercise) async {
    await _dao.updateExercise(exercise.copyWith(updatedAt: DateTime.now()));
    await loadExercises();
  }

  Future<void> deleteExercise(int id) async {
    await _dao.deleteExercise(id);
    await loadExercises();
  }
}

final exerciseProvider = StateNotifierProvider<ExerciseNotifier, AsyncValue<List<Exercise>>>((ref) {
  return ExerciseNotifier();
});

final exercisesByCategoryProvider = Provider.family<AsyncValue<List<Exercise>>, String>((ref, category) {
  final allExercises = ref.watch(exerciseProvider);
  return allExercises.whenData((list) => list.where((e) => e.category == category).toList());
});
