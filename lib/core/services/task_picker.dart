import 'dart:math';

import '../models/lesson.dart';
import '../models/srs_card.dart';
import '../models/word.dart';
import '../models/word_task.dart';
import '../repositories/content_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/srs_repository.dart';
import 'adaptive_store.dart';

class TaskPicker {
  factory TaskPicker({
    required ContentRepository content,
    required SrsRepository srs,
    required ProgressRepository progress,
    required AdaptiveStore adaptive,
    Random? random,
  }) {
    return TaskPicker._(
      content,
      srs,
      progress,
      adaptive,
      random ?? Random(),
    );
  }

  TaskPicker._(
    this._content,
    this._srs,
    this._progress,
    this._adaptive,
    this._random,
  );

  final ContentRepository _content;
  final SrsRepository _srs;
  final ProgressRepository _progress;
  final AdaptiveStore _adaptive;
  final Random _random;

  Future<WordTask?> pickForMove({
    required Lesson lesson,
    String? lastWordId,
    Set<String>? excludeWordIds,
    DateTime? now,
  }) async {
    final moment = now ?? DateTime.now();
    final excluded = excludeWordIds ?? const <String>{};
    final cards = await _srs.allCards();
    final due = await _dueSorted(moment);
    final dueWords = due
        .map((card) => _content.wordById(card.wordId))
        .whereType<Word>()
        .where((word) => !excluded.contains(word.id))
        .toList(growable: false);
    if (dueWords.isNotEmpty) {
      final word = _pickDueWords(dueWords, lastWordId);
      if (word != null) return _buildTask(word, lesson);
    }

    final unseen = lesson.vocabularyIds
        .where((id) => !cards.containsKey(id))
        .where((id) => !excluded.contains(id))
        .map(_content.wordById)
        .whereType<Word>()
        .toList(growable: false);
    final unseenChoice = _avoidLast(unseen, lastWordId);
    if (unseenChoice != null) return _buildTask(unseenChoice, lesson);

    final completed = await _progress.completedLessonIds();
    final counts = await _adaptive.wrongCounts(now: moment);
    final learnedPool = _content
        .wordsForLessons(completed)
        .where((word) => !excluded.contains(word.id))
        .where((word) => word.id != lastWordId)
        .toList(growable: false)
      ..sort(
        (a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0),
      );
    if (learnedPool.isNotEmpty) {
      final problem = learnedPool.where((word) => (counts[word.id] ?? 0) >= 3);
      final pool = problem.isNotEmpty
          ? problem.toList(growable: false)
          : learnedPool;
      return _buildTask(
        pool[_random.nextInt(pool.length)],
        lesson,
      );
    }

    final current = _content
        .wordsForLesson(lesson.id)
        .where((word) => !excluded.contains(word.id))
        .toList(growable: false);
    final fallback = _avoidLast(current, lastWordId);
    if (fallback != null) return _buildTask(fallback, lesson);

    // Все слова текущего пула уже встречались в этой партии — начинаем
    // новый круг, чтобы не блокировать ход.
    final allCurrent = _content.wordsForLesson(lesson.id);
    final repeat = _avoidLast(allCurrent, lastWordId);
    if (repeat != null) return _buildTask(repeat, lesson);
    return null;
  }

  Future<List<WordTask>> pickShootout({
    int count = 10,
    DateTime? now,
  }) async {
    final moment = now ?? DateTime.now();
    final cards = await _srs.allCards();
    final counts = await _adaptive.wrongCounts(now: moment);
    final due = await _dueSorted(moment);
    final selected = <Word>[];
    final used = <String>{};

    for (final card in due) {
      if (selected.length >= count) break;
      final word = _content.wordById(card.wordId);
      if (word != null && used.add(word.id)) selected.add(word);
    }

    // Слова с частыми ошибками показываем чаще, даже если интервал ещё не истёк.
    final problemCards = cards.values
        .where((card) => (counts[card.wordId] ?? 0) >= 3)
        .toList()
      ..sort(
        (a, b) =>
            (counts[b.wordId] ?? 0).compareTo(counts[a.wordId] ?? 0),
      );
    for (final card in problemCards) {
      if (selected.length >= count) break;
      final word = _content.wordById(card.wordId);
      if (word != null && used.add(word.id)) selected.add(word);
    }

    final learned = cards.values
        .where((card) => card.learned)
        .map((card) => _content.wordById(card.wordId))
        .whereType<Word>()
        .where((word) => !used.contains(word.id))
        .toList()
      ..sort((a, b) {
        final byWrong = (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0);
        if (byWrong != 0) return byWrong;
        return a.en.compareTo(b.en);
      });
    for (final word in learned) {
      if (selected.length >= count) break;
      if (used.add(word.id)) selected.add(word);
    }

    if (selected.isEmpty) return const <WordTask>[];
    final chosen = selected.take(count).toList(growable: false);
    if (chosen.length > 1) chosen.shuffle(_random);
    final lesson = _content.lessons.first;
    return Future.wait(
      chosen.map((word) => _buildTask(word, lesson)),
    );
  }

  Future<List<SrsCard>> _dueSorted(DateTime now) async {
    final cards = await _srs.dueCards(now: now);
    final counts = await _adaptive.wrongCounts(now: now);
    cards.sort((a, b) {
      final byWrong = (counts[b.wordId] ?? 0).compareTo(counts[a.wordId] ?? 0);
      if (byWrong != 0) return byWrong;
      final aWrong = a.lastResult == SrsResult.wrong ? 1 : 0;
      final bWrong = b.lastResult == SrsResult.wrong ? 1 : 0;
      if (aWrong != bWrong) return bWrong.compareTo(aWrong);
      final byDate = a.nextReviewAt.compareTo(b.nextReviewAt);
      if (byDate != 0) return byDate;
      return a.ease.compareTo(b.ease);
    });
    return cards;
  }

  Word? _pickDueWords(List<Word> words, String? lastWordId) {
    if (words.isEmpty) return null;
    if (words.length > 1 && words.first.id == lastWordId) {
      return words[1];
    }
    return words.first;
  }

  Word? _avoidLast(List<Word> words, String? lastWordId) {
    if (words.isEmpty) return null;
    final options =
        words.where((word) => word.id != lastWordId).toList(growable: false);
    final pool = options.isEmpty ? words : options;
    return pool[_random.nextInt(pool.length)];
  }

  Future<WordTask> _buildTask(Word word, Lesson lesson) async {
    await _srs.ensureCard(word.id);
    final all = _content.words;
    final distractors = all
        .where((item) => item.id != word.id && item.ru != word.ru)
        .map((item) => item.ru)
        .toSet()
        .toList()
      ..shuffle(_random);
    final options = <String>[word.ru, ...distractors.take(2)]
      ..shuffle(_random);
    final correct = options.indexOf(word.ru);
    final contextLesson = _content.lessonById(word.lessonId) ?? lesson;
    return WordTask(
      word: word,
      options: options,
      correctIndex: correct,
      hint:
          '${word.transcription} · ${word.partOfSpeech} · урок «${contextLesson.title}»',
    );
  }
}
