import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gym_app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE training_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_number INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight_kg REAL NOT NULL,
        reps INTEGER NOT NULL,
        rpe REAL,
        is_failure INTEGER DEFAULT 0,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES training_sessions(id),
        FOREIGN KEY (exercise_id) REFERENCES exercises(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE body_weights (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight_kg REAL NOT NULL,
        recorded_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedDefaultExercises(db);
  }

  Future<void> _seedDefaultExercises(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      // 胸
      {'name': '杠铃卧推', 'category': 'chest', 'created_at': now, 'updated_at': now},
      {'name': '哑铃卧推', 'category': 'chest', 'created_at': now, 'updated_at': now},
      {'name': '上斜卧推', 'category': 'chest', 'created_at': now, 'updated_at': now},
      {'name': '哑铃飞鸟', 'category': 'chest', 'created_at': now, 'updated_at': now},
      {'name': '绳索夹胸', 'category': 'chest', 'created_at': now, 'updated_at': now},
      // 背
      {'name': '引体向上', 'category': 'back', 'created_at': now, 'updated_at': now},
      {'name': '杠铃划船', 'category': 'back', 'created_at': now, 'updated_at': now},
      {'name': '高位下拉', 'category': 'back', 'created_at': now, 'updated_at': now},
      {'name': '哑铃划船', 'category': 'back', 'created_at': now, 'updated_at': now},
      {'name': '坐姿划船', 'category': 'back', 'created_at': now, 'updated_at': now},
      // 腿
      {'name': '杠铃深蹲', 'category': 'legs', 'created_at': now, 'updated_at': now},
      {'name': '罗马尼亚硬拉', 'category': 'legs', 'created_at': now, 'updated_at': now},
      {'name': '腿举', 'category': 'legs', 'created_at': now, 'updated_at': now},
      {'name': '腿弯举', 'category': 'legs', 'created_at': now, 'updated_at': now},
      {'name': '保加利亚分腿蹲', 'category': 'legs', 'created_at': now, 'updated_at': now},
      // 肩
      {'name': '杠铃推举', 'category': 'shoulders', 'created_at': now, 'updated_at': now},
      {'name': '哑铃侧平举', 'category': 'shoulders', 'created_at': now, 'updated_at': now},
      {'name': '俯身飞鸟', 'category': 'shoulders', 'created_at': now, 'updated_at': now},
      {'name': '面拉', 'category': 'shoulders', 'created_at': now, 'updated_at': now},
      // 手臂
      {'name': '杠铃弯举', 'category': 'arms', 'created_at': now, 'updated_at': now},
      {'name': '锤式弯举', 'category': 'arms', 'created_at': now, 'updated_at': now},
      {'name': '绳索下压', 'category': 'arms', 'created_at': now, 'updated_at': now},
      {'name': '窄距卧推', 'category': 'arms', 'created_at': now, 'updated_at': now},
      // 核心
      {'name': '平板支撑', 'category': 'core', 'created_at': now, 'updated_at': now},
      {'name': '卷腹', 'category': 'core', 'created_at': now, 'updated_at': now},
      {'name': '悬垂举腿', 'category': 'core', 'created_at': now, 'updated_at': now},
    ];

    for (final exercise in defaults) {
      await db.insert('exercises', exercise);
    }
  }
}
