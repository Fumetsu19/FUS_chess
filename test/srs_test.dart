import 'package:chess_english/core/db/app_database.dart';
import 'package:chess_english/core/models/srs_card.dart';
import 'package:chess_english/core/repositories/srs_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'test_helpers.dart';

void main() {
  late AppDatabase database;
  late SrsRepository srs;
  final now = DateTime(2026, 1, 10, 12);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await openTestDatabase();
    srs = SrsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('карточка создаётся с interval=1, ease=2.5, reviews=0', () async {
    final card = await srs.ensureCard('w1', now: now);
    expect(card.intervalDays, 1);
    expect(card.ease, 2.5);
    expect(card.reviews, 0);
    expect(card.lastResult, isNull);
    expect(card.nextReviewAt.isAtSameMomentAs(
      now.add(const Duration(days: 1)),
    ), isTrue);
    expect(await srs.dueCount(now: now), 0);
  });

  test('correct: reviews++, интервал растёт, ease ограничен 2.5', () async {
    final first = await srs.recordAttempt('w1', correct: true, now: now);
    expect(first.reviews, 1);
    expect(first.intervalDays, 3);
    expect(first.ease, 2.5);
    expect(first.lastResult, SrsResult.correct);
    expect(first.nextReviewAt.isAtSameMomentAs(
      now.add(const Duration(days: 3)),
    ), isTrue);

    final second = await srs.recordAttempt(
      'w1',
      correct: true,
      now: now.add(const Duration(days: 3)),
    );
    expect(second.reviews, 2);
    expect(second.intervalDays, 8);
    expect(second.ease, 2.5);
    expect(second.learned, isTrue);
  });

  test('wrong: интервал сбрасывается, ease уменьшается, reviews не растёт',
      () async {
    await srs.recordAttempt('w1', correct: true, now: now);
    final wrong = await srs.recordAttempt(
      'w1',
      correct: false,
      now: now.add(const Duration(days: 1)),
    );
    expect(wrong.reviews, 1);
    expect(wrong.intervalDays, 1);
    expect(wrong.ease, closeTo(2.3, 0.0001));
    expect(wrong.lastResult, SrsResult.wrong);
    expect(wrong.nextReviewAt.isAtSameMomentAs(
      now.add(const Duration(days: 2)),
    ), isTrue);
  });

  test('мягкий режим перестрелки не меняет interval и next_review_at',
      () async {
    final base = await srs.ensureCard('w1', now: now);
    final softWrong = await srs.recordAttempt(
      'w1',
      correct: false,
      now: now.add(const Duration(days: 2)),
      soft: true,
    );
    expect(softWrong.intervalDays, base.intervalDays);
    expect(
      softWrong.nextReviewAt.isAtSameMomentAs(base.nextReviewAt),
      isTrue,
    );
    expect(softWrong.ease, closeTo(2.3, 0.0001));

    final softCorrect = await srs.recordAttempt(
      'w1',
      correct: true,
      now: now.add(const Duration(days: 3)),
      soft: true,
    );
    expect(softCorrect.reviews, 1);
    expect(softCorrect.intervalDays, base.intervalDays);
    expect(
      softCorrect.nextReviewAt.isAtSameMomentAs(base.nextReviewAt),
      isTrue,
    );
    expect(softCorrect.lastResult, SrsResult.correct);
  });

  test('просроченная карточка попадает в dueCount', () async {
    await srs.ensureCard('w1', now: now.subtract(const Duration(days: 3)));
    expect(await srs.dueCount(now: now), 1);
    final due = await srs.dueCards(now: now);
    expect(due.single.wordId, 'w1');
  });
}
