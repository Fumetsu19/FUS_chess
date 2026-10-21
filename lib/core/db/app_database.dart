import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
      : _factory = factory ?? databaseFactory,
        _customPath = path;

  final DatabaseFactory _factory;
  final String? _customPath;
  Database? _db;

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('База данных ещё не открыта');
    }
    return database;
  }

  Future<void> open() async {
    if (_db != null) return;
    final path = _customPath ??
        p.join(await _factory.getDatabasesPath(), 'chess_english.db');
    _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          await createSchema(database);
        },
      ),
    );
  }

  Future<void> close() async {
    final database = _db;
    _db = null;
    await database?.close();
  }

  Future<void> clearAll() async {
    await db.transaction((transaction) async {
      await transaction.delete('srs_cards');
      await transaction.delete('lesson_progress');
      await transaction.delete('session_stats');
    });
  }

  static Future<void> createSchema(Database database) async {
    await database.execute('''
CREATE TABLE srs_cards (
  word_id        TEXT PRIMARY KEY,
  interval_days  INTEGER NOT NULL DEFAULT 1,
  ease           REAL    NOT NULL DEFAULT 2.5,
  reviews        INTEGER NOT NULL DEFAULT 0,
  next_review_at TEXT    NOT NULL,
  last_result    TEXT
)
''');
    await database.execute('''
CREATE TABLE lesson_progress (
  lesson_id     TEXT PRIMARY KEY,
  completed_at  TEXT,
  exercises_ok  INTEGER NOT NULL DEFAULT 0,
  exercises_all INTEGER NOT NULL DEFAULT 0
)
''');
    await database.execute('''
CREATE TABLE session_stats (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  played_at        TEXT NOT NULL,
  lesson_id        TEXT,
  tasks_total      INTEGER,
  tasks_first_try  INTEGER,
  moves_made       INTEGER,
  game_result      TEXT
)
''');
    await database.execute(
      'CREATE INDEX idx_srs_next_review ON srs_cards(next_review_at)',
    );
    await database.execute(
      'CREATE INDEX idx_session_played_at ON session_stats(played_at)',
    );
  }
}
