import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/lesson.dart';
import '../models/reading.dart';
import '../models/word.dart';

class ContentRepository {
  ContentRepository({
    required LessonPack lessonPack,
    required VocabularyPack vocabularyPack,
    ReadingPack? readingPack,
  })  : lessonPack = lessonPack,
        vocabularyPack = vocabularyPack,
        readingPack = readingPack ?? ReadingPack.empty {
    _validate();
    for (final lesson in lessonPack.lessons) {
      _lessonsById[lesson.id] = lesson;
    }
    for (final word in vocabularyPack.words) {
      _wordsById[word.id] = word;
    }
  }

  final LessonPack lessonPack;
  final VocabularyPack vocabularyPack;
  final ReadingPack readingPack;
  final Map<String, Lesson> _lessonsById = {};
  final Map<String, Word> _wordsById = {};

  List<Lesson> get lessons => lessonPack.lessons;
  List<Word> get words => vocabularyPack.words;
  int get plannedTotal => lessonPack.plannedTotal;
  List<ReadingPassage> get readingPassages => readingPack.passages;

  Lesson? lessonById(String id) => _lessonsById[id];
  Word? wordById(String id) => _wordsById[id];

  List<Word> wordsForLesson(String lessonId) {
    final lesson = _lessonsById[lessonId];
    if (lesson == null) return const <Word>[];
    return lesson.vocabularyIds
        .map((id) => _wordsById[id])
        .whereType<Word>()
        .toList(growable: false);
  }

  List<Word> wordsForLessons(Set<String> lessonIds) {
    final result = <Word>[];
    for (final lesson in lessons) {
      if (!lessonIds.contains(lesson.id)) continue;
      result.addAll(wordsForLesson(lesson.id));
    }
    return result;
  }

  Lesson? lessonForWord(String wordId) {
    final word = _wordsById[wordId];
    return word == null ? null : _lessonsById[word.lessonId];
  }

  List<Word> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return words;
    return words
        .where(
          (word) =>
              word.en.toLowerCase().contains(normalized) ||
              word.ru.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  static Future<ContentRepository> loadFromAssets() async {
    final lessonsJson = jsonDecode(
      await rootBundle.loadString('assets/data/lessons.json'),
    );
    final vocabularyJson = jsonDecode(
      await rootBundle.loadString('assets/data/vocabulary.json'),
    );
    final readingJson = jsonDecode(
      await rootBundle.loadString('assets/data/b1_reading.json'),
    );
    if (lessonsJson is! Map ||
        vocabularyJson is! Map ||
        readingJson is! Map) {
      throw const FormatException('Корень JSON-файлов должен быть объектом');
    }
    return ContentRepository(
      lessonPack:
          LessonPack.fromJson(Map<String, dynamic>.from(lessonsJson)),
      vocabularyPack:
          VocabularyPack.fromJson(Map<String, dynamic>.from(vocabularyJson)),
      readingPack: ReadingPack.fromJson(
        Map<String, dynamic>.from(readingJson),
      ),
    );
  }

  void _validate() {
    if (lessonPack.lessons.isEmpty) {
      throw const FormatException('lessons.json: нет ни одного урока');
    }
    final lessonIds = <String>{};
    for (final lesson in lessonPack.lessons) {
      if (!lessonIds.add(lesson.id)) {
        throw FormatException('lessons.json: дубль урока ${lesson.id}');
      }
      if (lesson.vocabularyIds.isEmpty) {
        throw FormatException('Урок ${lesson.id}: пустой vocabulary_ids');
      }
      if (lesson.exercises.isEmpty) {
        throw FormatException('Урок ${lesson.id}: нет упражнений');
      }
    }
    final wordIds = <String>{};
    for (final word in vocabularyPack.words) {
      if (!wordIds.add(word.id)) {
        throw FormatException('vocabulary.json: дубль слова ${word.id}');
      }
      if (!lessonIds.contains(word.lessonId)) {
        throw FormatException(
          'Слово ${word.id} ссылается на неизвестный урок ${word.lessonId}',
        );
      }
    }
    for (final lesson in lessonPack.lessons) {
      for (final id in lesson.vocabularyIds) {
        if (!wordIds.contains(id)) {
          throw FormatException(
            'Урок ${lesson.id} ссылается на неизвестное слово $id',
          );
        }
      }
    }
  }
}
