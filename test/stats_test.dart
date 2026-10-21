import 'package:chess_english/core/db/app_database.dart';
import 'package:chess_english/core/models/game_summary.dart';
import 'package:chess_english/core/repositories/progress_repository.dart';
import 'package:chess_english/core/repositories/stats_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase database;
  late StatsRepository stats;
  late ProgressRepository progress;
  final now = DateTime(2026, 1, 10, 12);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await openTestDatabase();
    stats = StatsRepository(database);
    progress = ProgressRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('сессия, задачи, ходы и результат попадают в статистику', () async {
    final today = await stats.startSession(lessonId: 'lesson_01', now: now);
    await stats.addTask(today, firstTry: true);
    await stats.addTask(today, firstTry: false);
    await stats.addPlayerMove(today);
    await stats.finishSession(today, GameOutcome.win);

    final yesterday = await stats.startSession(
      now: now.subtract(const Duration(days: 1)),
    );
    await stats.addTask(yesterday, firstTry: true);
    await stats.addPlayerMove(yesterday);
    await stats.finishSession(yesterday, GameOutcome.loss);

    final record = await stats.session(today);
    expect(record, isNotNull);
    expect(record!.tasksTotal, 2);
    expect(record.tasksFirstTry, 1);
    expect(record.movesMade, 1);
    expect(record.gameResult, 'win');

    final profile = await stats.profileStats(now: now);
    expect(profile.totalTasks, 3);
    expect(profile.tasksFirstTry, 2);
    expect(profile.accuracy, closeTo(2 / 3, 0.0001));
    expect(profile.gamesPlayed, 2);
    expect(profile.wins, 1);
    expect(profile.streakDays, 2);
  });

  test('урок и дневная цель: 1 урок или 5 задач', () async {
    final session = await stats.startSession(now: now);
    await stats.addTask(session, firstTry: true);
    await stats.addTask(session, firstTry: true);
    await stats.finishSession(session, null);

    var goal = await stats.dailyGoal(now: now);
    expect(goal.tasksToday, 2);
    expect(goal.lessonsToday, 0);
    expect(goal.achieved, isFalse);

    await progress.saveLessonResult(
      lessonId: 'lesson_01',
      exercisesOk: 2,
      exercisesAll: 3,
      completedAt: now,
    );
    final completed = await progress.completedLessonIds();
    expect(completed, contains('lesson_01'));

    goal = await stats.dailyGoal(now: now);
    expect(goal.lessonsToday, 1);
    expect(goal.achieved, isTrue);

    final profile = await stats.profileStats(now: now);
    expect(profile.lessonsCompleted, 1);
  });

  test('aborted-сессия без ходов не считается сыгранной партией', () async {
    final session = await stats.startSession(lessonId: 'lesson_01', now: now);
    await stats.finishSession(session, GameOutcome.aborted);
    final profile = await stats.profileStats(now: now);
    expect(profile.gamesPlayed, 0);
  });

  test('серия дней считается по активности и завершённым урокам', () async {
    final yesterday = await stats.startSession(
      now: now.subtract(const Duration(days: 1)),
    );
    await stats.addTask(yesterday, firstTry: true);
    await stats.finishSession(yesterday, null);
    await progress.saveLessonResult(
      lessonId: 'lesson_02',
      exercisesOk: 1,
      exercisesAll: 1,
      completedAt: now.subtract(const Duration(days: 2)),
    );

    expect(await stats.streakDays(now: now), 2);
  });
}
