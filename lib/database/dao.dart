import 'package:sqflite/sqflite.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/training_session.dart';
import '../models/body_weight.dart';
import 'database_helper.dart';

class Dao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ---- Exercises ----

  Future<List<Exercise>> getExercises({String? category}) async {
    final db = await _dbHelper.database;
    String where = 'is_deleted = 0';
    List<dynamic> args = [];
    if (category != null) {
      where += ' AND category = ?';
      args.add(category);
    }
    final maps = await db.query('exercises', where: where, whereArgs: args, orderBy: 'category, name');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<Exercise?> getExercise(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercises', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<int> insertExercise(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.insert('exercises', exercise.toMap());
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await _dbHelper.database;
    return await db.update('exercises', exercise.toMap(), where: 'id = ?', whereArgs: [exercise.id]);
  }

  Future<int> deleteExercise(int id) async {
    final db = await _dbHelper.database;
    return await db.update('exercises', {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  // ---- Training Sessions ----

  Future<List<TrainingSession>> getSessions({int? cycleNumber, int limit = 50}) async {
    final db = await _dbHelper.database;
    String where = '1=1';
    List<dynamic> args = [];
    if (cycleNumber != null) {
      where += ' AND cycle_number = ?';
      args.add(cycleNumber);
    }
    final maps = await db.query('training_sessions',
        where: where, whereArgs: args, orderBy: 'started_at DESC', limit: limit);
    return maps.map((m) => TrainingSession.fromMap(m)).toList();
  }

  Future<TrainingSession?> getSession(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('training_sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final session = TrainingSession.fromMap(maps.first);
    final sets = await getSetsForSession(id);
    return session.copyWith(endedAt: session.endedAt)..sets?.addAll(sets);
  }

  Future<int> insertSession(TrainingSession session) async {
    final db = await _dbHelper.database;
    return await db.insert('training_sessions', session.toMap());
  }

  Future<int> updateSession(TrainingSession session) async {
    final db = await _dbHelper.database;
    return await db.update('training_sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<int> getCurrentCycleNumber() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT MAX(cycle_number) as max_cycle FROM training_sessions');
    if (result.first['max_cycle'] == null) return 1;
    return (result.first['max_cycle'] as int?) ?? 1;
  }

  /// Get all unique categories trained in the current cycle
  Future<Set<String>> getTrainedCategoriesInCycle(int cycleNumber) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT DISTINCT e.category
      FROM exercise_sets es
      JOIN training_sessions ts ON es.session_id = ts.id
      JOIN exercises e ON es.exercise_id = e.id
      WHERE ts.cycle_number = ?
    ''', [cycleNumber]);
    return result.map((r) => r['category'] as String).toSet();
  }

  // ---- Exercise Sets ----

  Future<List<ExerciseSet>> getSetsForSession(int sessionId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercise_sets',
        where: 'session_id = ?', whereArgs: [sessionId], orderBy: 'exercise_id, set_number');
    return maps.map((m) => ExerciseSet.fromMap(m)).toList();
  }

  Future<List<ExerciseSet>> getHistoryForExercise(int exerciseId, {int limit = 100}) async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercise_sets',
        where: 'exercise_id = ?', whereArgs: [exerciseId], orderBy: 'recorded_at DESC', limit: limit);
    return maps.map((m) => ExerciseSet.fromMap(m)).toList();
  }

  Future<ExerciseSet?> getLastSetForExercise(int exerciseId) async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercise_sets',
        where: 'exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'recorded_at DESC',
        limit: 1);
    if (maps.isEmpty) return null;
    return ExerciseSet.fromMap(maps.first);
  }

  Future<int> insertExerciseSet(ExerciseSet set) async {
    final db = await _dbHelper.database;
    return await db.insert('exercise_sets', set.toMap());
  }

  Future<int> updateExerciseSet(ExerciseSet set) async {
    final db = await _dbHelper.database;
    return await db.update('exercise_sets', set.toMap(), where: 'id = ?', whereArgs: [set.id]);
  }

  Future<int> deleteExerciseSet(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('exercise_sets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getNextSetNumber(int sessionId, int exerciseId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(set_number) as max_set FROM exercise_sets WHERE session_id = ? AND exercise_id = ?',
      [sessionId, exerciseId],
    );
    return ((result.first['max_set'] as int?) ?? 0) + 1;
  }

  // ---- Body Weight ----

  Future<List<BodyWeight>> getBodyWeights({int limit = 100}) async {
    final db = await _dbHelper.database;
    final maps = await db.query('body_weights', orderBy: 'recorded_at DESC', limit: limit);
    return maps.map((m) => BodyWeight.fromMap(m)).toList();
  }

  Future<BodyWeight?> getLatestBodyWeight() async {
    final db = await _dbHelper.database;
    final maps = await db.query('body_weights', orderBy: 'recorded_at DESC', limit: 1);
    if (maps.isEmpty) return null;
    return BodyWeight.fromMap(maps.first);
  }

  Future<int> insertBodyWeight(BodyWeight bw) async {
    final db = await _dbHelper.database;
    return await db.insert('body_weights', bw.toMap());
  }

  // ---- User Settings ----

  Future<String?> getSetting(String key) async {
    final db = await _dbHelper.database;
    final maps = await db.query('user_settings', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert('user_settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ---- Export helpers ----

  Future<List<Exercise>> getAllExercisesForExport() async {
    final db = await _dbHelper.database;
    final maps = await db.query('exercises', where: 'is_deleted = 0', orderBy: 'id');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<List<TrainingSession>> getAllSessionsForExport() async {
    final db = await _dbHelper.database;
    final maps = await db.query('training_sessions', orderBy: 'started_at');
    final sessions = maps.map((m) => TrainingSession.fromMap(m)).toList();
    for (final session in sessions) {
      final sets = await getSetsForSession(session.id!);
      session.sets?.addAll(sets);
    }
    return sessions;
  }

  Future<void> importData(Exercise exercise) async {
    final db = await _dbHelper.database;
    await db.insert('exercises', exercise.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> importSession(TrainingSession session) async {
    final db = await _dbHelper.database;
    await db.insert('training_sessions', session.toMap());
    if (session.sets != null) {
      for (final set in session.sets!) {
        await db.insert('exercise_sets', set.toMap());
      }
    }
  }

  Future<void> importBodyWeight(BodyWeight bw) async {
    final db = await _dbHelper.database;
    await db.insert('body_weights', bw.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
