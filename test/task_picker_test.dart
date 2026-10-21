import 'dart:math';

import 'package:chess_english/core/db/app_database.dart';
import 'package:chess_english/core/repositories/progress_repository.dart';
import 'package:chess_english/core/repositories/srs_repository.dart';
import 'package:chess_english/core/services/adaptive_store.dart';
import 'package:chess_english/core/services/task_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase database;
  late SrsRepository srs;
  late ProgressRepository progress;
  late AdaptiveStore adaptive;
  late TaskPicker picker;
  final now = DateTime(2026, 1, 10, 12);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    database = await openTestDatabase();
    srs = SrsRepository(database);
    progress = ProgressRepository(database);
    adaptive = AdaptiveStore(prefs);
    final content = testContent();
    picker = TaskPicker(
      content: content,
      srs: srs,
      progress: progress,
      adaptive: adaptive,
      random: Random(7),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('приоритет 1: просроченная карточка важнее слов текущего урока',
      () async {
    await srs.recordAttempt(
      'w1',
      correct: false,
      now: now.subtract(const Duration(days: 2)),
    );
    final task = await picker.pickForMove(
      lesson: testContent().lessonById('l2')!,
      now: now,
    );
    expect(task, isNotNull);
    expect(task!.word.id, 'w1');
    expect(task.options, contains(task.word.ru));
    expect(task.options.length, 3);
    expect(task.correctAnswer, task.word.ru);
  });

  test('приоритет 2: слова текущего урока, которых нет в SRS', () async {
    final lesson = testContent().lessonById('l2')!;
    final task = await picker.pickForMove(lesson: lesson, now: now);
    expect(task, isNotNull);
    expect(lesson.vocabularyIds, contains(task!.word.id));
    expect(await srs.card(task.word.id), isNotNull);
  });

  test('приоритет 3: слова из завершённых уроков', () async {
    for (final id in <String>['w4', 'w5', 'w6']) {
      await srs.ensureCard(id, now: now);
    }
    await progress.saveLessonResult(
      lessonId: 'l1',
      exercisesOk: 1,
      exercisesAll: 1,
      completedAt: now,
    );
    final task = await picker.pickForMove(
      lesson: testContent().lessonById('l2')!,
      now: now,
    );
    expect(task, isNotNull);
    expect(<String>['w1', 'w2', 'w3'], contains(task!.word.id));
  });

  test('перестрелка пуста без due/изученных, затем берёт изученное',
      () async {
    expect(await picker.pickShootout(now: now), isEmpty);
    await srs.recordAttempt('w1', correct: true, now: now);
    final tasks = await picker.pickShootout(now: now);
    expect(tasks, isNotEmpty);
    expect(tasks.first.word.id, 'w1');
  });

  test('слова с ошибками за последние 7 дней идут раньше при выборе due',
      () async {
    await srs.ensureCard('w1', now: now.subtract(const Duration(days: 3)));
    await srs.ensureCard('w2', now: now.subtract(const Duration(days: 3)));
    await adaptive.recordWrong('w2', now: now);
    await adaptive.recordWrong('w2', now: now);
    final task = await picker.pickForMove(
      lesson: testContent().lessonById('l2')!,
      now: now,
    );
    expect(task!.word.id, 'w2');
  });

  test('в одной партии слова не повторяются, пока пул не исчерпан', () async {
    final lesson = testContent().lessonById('l2')!;
    final used = <String>{};
    for (var i = 0; i < 3; i++) {
      final task = await picker.pickForMove(
        lesson: lesson,
        excludeWordIds: used,
        now: now,
      );
      expect(task, isNotNull);
      expect(used.add(task!.word.id), isTrue);
    }
  });
}
