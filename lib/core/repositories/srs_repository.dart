import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/srs_card.dart';

class SrsRepository {
  SrsRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  Future<SrsCard?> card(String wordId) async {
    final rows = await _db.query(
      'srs_cards',
      where: 'word_id = ?',
      whereArgs: <Object?>[wordId],
      limit: 1,
    );
    return rows.isEmpty ? null : SrsCard.fromMap(rows.first);
  }

  Future<Map<String, SrsCard>> allCards() async {
    final rows = await _db.query('srs_cards');
    return <String, SrsCard>{
      for (final row in rows)
        row['word_id']! as String: SrsCard.fromMap(row),
    };
  }

  Future<SrsCard> ensureCard(String wordId, {DateTime? now}) async {
    final existing = await card(wordId);
    if (existing != null) return existing;
    final moment = now ?? DateTime.now();
    final next = moment.add(const Duration(days: 1));
    await _db.insert(
      'srs_cards',
      <String, Object?>{
        'word_id': wordId,
        'interval_days': 1,
        'ease': 2.5,
        'reviews': 0,
        'next_review_at': next.toUtc().toIso8601String(),
        'last_result': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return (await card(wordId))!;
  }

  Future<SrsCard> recordAttempt(
    String wordId, {
    required bool correct,
    DateTime? now,
    bool soft = false,
  }) async {
    final moment = now ?? DateTime.now();
    final current = await ensureCard(wordId, now: moment);
    late final SrsCard updated;
    if (correct) {
      final reviews = current.reviews + 1;
      final ease = math.min(2.5, current.ease + 0.1);
      if (soft) {
        updated = current.copyWith(
          reviews: reviews,
          ease: ease,
          lastResult: SrsResult.correct,
        );
      } else {
        final interval = math.max(
          1,
          (current.intervalDays * current.ease).round(),
        );
        updated = current.copyWith(
          reviews: reviews,
          ease: ease,
          intervalDays: interval,
          nextReviewAt: moment.add(Duration(days: interval)),
          lastResult: SrsResult.correct,
        );
      }
    } else {
      final ease = math.max(1.3, current.ease - 0.2);
      if (soft) {
        updated = current.copyWith(
          ease: ease,
          lastResult: SrsResult.wrong,
        );
      } else {
        updated = current.copyWith(
          ease: ease,
          intervalDays: 1,
          nextReviewAt: moment.add(const Duration(days: 1)),
          lastResult: SrsResult.wrong,
        );
      }
    }
    await _db.update(
      'srs_cards',
      <String, Object?>{
        'interval_days': updated.intervalDays,
        'ease': updated.ease,
        'reviews': updated.reviews,
        'next_review_at': updated.nextReviewAt.toUtc().toIso8601String(),
        'last_result': updated.lastResult?.dbValue,
      },
      where: 'word_id = ?',
      whereArgs: <Object?>[wordId],
    );
    return updated;
  }

  Future<List<SrsCard>> dueCards({DateTime? now}) async {
    final moment = now ?? DateTime.now();
    final rows = await _db.query(
      'srs_cards',
      where: 'next_review_at <= ?',
      whereArgs: <Object?>[moment.toUtc().toIso8601String()],
      orderBy: 'next_review_at ASC',
    );
    return rows.map(SrsCard.fromMap).toList(growable: false);
  }

  Future<int> dueCount({DateTime? now}) async {
    final moment = now ?? DateTime.now();
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) AS c FROM srs_cards WHERE next_review_at <= ?',
      <Object?>[moment.toUtc().toIso8601String()],
    );
    return (rows.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<List<SrsCard>> weakCards() async {
    final rows = await _db.query(
      'srs_cards',
      where: 'last_result = ?',
      whereArgs: <Object?>[SrsResult.wrong.dbValue],
      orderBy: 'ease ASC',
    );
    return rows.map(SrsCard.fromMap).toList(growable: false);
  }

  Future<List<SrsCard>> learnedCards() async {
    final rows = await _db.query(
      'srs_cards',
      where: 'reviews >= 1 AND last_result = ?',
      whereArgs: <Object?>[SrsResult.correct.dbValue],
    );
    return rows.map(SrsCard.fromMap).toList(growable: false);
  }

  Future<void> clearAll() async {
    await _db.delete('srs_cards');
  }
}
