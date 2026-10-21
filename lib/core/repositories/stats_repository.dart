import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/game_summary.dart';
import '../models/progress.dart';

class StatsRepository {
  StatsRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  Future<int> startSession({String? lessonId, DateTime? now}) async {
    return _db.insert('session_stats', <String, Object?>{
      'played_at': (now ?? DateTime.now()).toIso8601String(),
      'lesson_id': lessonId,
      'tasks_total': 0,
      'tasks_first_try': 0,
      'moves_made': 0,
      'game_result': null,
    });
  }

  Future<void> addTask(int sessionId, {required bool firstTry}) async {
    await _db.rawUpdate(
      '''
UPDATE session_stats
SET tasks_total = COALESCE(tasks_total, 0) + 1,
    tasks_first_try = COALESCE(tasks_first_try, 0) + ?
WHERE id = ?
''',
      <Object?>[firstTry ? 1 : 0, sessionId],
    );
  }

  Future<void> addPlayerMove(int sessionId) async {
    await _db.rawUpdate(
      '''
UPDATE session_stats
SET moves_made = COALESCE(moves_made, 0) + 1
WHERE id = ?
''',
      <Object?>[sessionId],
    );
  }

  Future<void> finishSession(
    int sessionId,
    GameOutcome? outcome,
  ) async {
    await _db.update(
      'session_stats',
      <String, Object?>{'game_result': outcome?.dbValue},
      where: 'id = ?',
      whereArgs: <Object?>[sessionId],
    );
  }

  Future<SessionRecord?> session(int sessionId) async {
    final rows = await _db.query(
      'session_stats',
      where: 'id = ?',
      whereArgs: <Object?>[sessionId],
      limit: 1,
    );
    return rows.isEmpty ? null : SessionRecord.fromMap(rows.first);
  }

  Future<ProfileStats> profileStats({DateTime? now}) async {
    final totals = await _db.rawQuery('''
SELECT
  COALESCE(SUM(tasks_total), 0) AS total_tasks,
  COALESCE(SUM(tasks_first_try), 0) AS first_try,
  COALESCE(SUM(CASE WHEN game_result IS NOT NULL AND (COALESCE(moves_made, 0) > 0 OR game_result != 'aborted') THEN 1 ELSE 0 END), 0) AS games,
  COALESCE(SUM(CASE WHEN game_result = 'win' THEN 1 ELSE 0 END), 0) AS wins
FROM session_stats
''');
    final lessons = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM lesson_progress WHERE completed_at IS NOT NULL',
    );
    final totalRow = totals.first;
    return ProfileStats(
      totalTasks: (totalRow['total_tasks'] as num?)?.toInt() ?? 0,
      tasksFirstTry: (totalRow['first_try'] as num?)?.toInt() ?? 0,
      gamesPlayed: (totalRow['games'] as num?)?.toInt() ?? 0,
      wins: (totalRow['wins'] as num?)?.toInt() ?? 0,
      lessonsCompleted: (lessons.first['c'] as num?)?.toInt() ?? 0,
      streakDays: await streakDays(now: now),
    );
  }

  Future<DailyGoal> dailyGoal({DateTime? now}) async {
    final today = _dayKey(now ?? DateTime.now());
    final tasks = await _db.rawQuery(
      '''
SELECT COALESCE(SUM(tasks_total), 0) AS tasks
FROM session_stats
WHERE substr(played_at, 1, 10) = ?
''',
      <Object?>[today],
    );
    final lessons = await _db.rawQuery(
      '''
SELECT COUNT(*) AS c
FROM lesson_progress
WHERE completed_at IS NOT NULL AND substr(completed_at, 1, 10) = ?
''',
      <Object?>[today],
    );
    return DailyGoal(
      tasksToday: (tasks.first['tasks'] as num?)?.toInt() ?? 0,
      lessonsToday: (lessons.first['c'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> streakDays({DateTime? now}) async {
    final dates = await _activityDates();
    if (dates.isEmpty) return 0;
    var cursor = _dateOnly(now ?? DateTime.now());
    if (!dates.contains(_dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (dates.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<Set<String>> _activityDates() async {
    final sessions = await _db.rawQuery('''
SELECT DISTINCT substr(played_at, 1, 10) AS day
FROM session_stats
WHERE COALESCE(tasks_total, 0) > 0 OR COALESCE(moves_made, 0) > 0
''');
    final lessons = await _db.rawQuery('''
SELECT DISTINCT substr(completed_at, 1, 10) AS day
FROM lesson_progress
WHERE completed_at IS NOT NULL
''');
    return <String>{
      for (final row in sessions) row['day']! as String,
      for (final row in lessons) row['day']! as String,
    };
  }

  Future<void> clearAll() async {
    await _db.delete('session_stats');
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _dayKey(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
