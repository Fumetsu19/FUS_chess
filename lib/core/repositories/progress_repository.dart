import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/progress.dart';

class ProgressRepository {
  ProgressRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  Future<List<LessonProgress>> all() async {
    final rows = await _db.query('lesson_progress', orderBy: 'lesson_id');
    return rows.map(LessonProgress.fromMap).toList(growable: false);
  }

  Future<LessonProgress?> forLesson(String lessonId) async {
    final rows = await _db.query(
      'lesson_progress',
      where: 'lesson_id = ?',
      whereArgs: <Object?>[lessonId],
      limit: 1,
    );
    return rows.isEmpty ? null : LessonProgress.fromMap(rows.first);
  }

  Future<Set<String>> completedLessonIds() async {
    final rows = await _db.query(
      'lesson_progress',
      columns: <String>['lesson_id'],
      where: 'completed_at IS NOT NULL',
    );
    return rows.map((row) => row['lesson_id']! as String).toSet();
  }

  Future<void> saveLessonResult({
    required String lessonId,
    required int exercisesOk,
    required int exercisesAll,
    DateTime? completedAt,
  }) async {
    await _db.insert(
      'lesson_progress',
      <String, Object?>{
        'lesson_id': lessonId,
        'completed_at': (completedAt ?? DateTime.now()).toIso8601String(),
        'exercises_ok': exercisesOk,
        'exercises_all': exercisesAll,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAll() async {
    await _db.delete('lesson_progress');
  }
}
