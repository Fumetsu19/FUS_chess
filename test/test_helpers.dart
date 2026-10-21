import 'package:chess_english/core/models/cefr_level.dart';
import 'package:chess_english/core/models/lesson.dart';
import 'package:chess_english/core/models/word.dart';
import 'package:chess_english/core/repositories/content_repository.dart';
import 'package:chess_english/core/services/adaptive_store.dart';
import 'package:chess_english/core/services/app_services.dart';
import 'package:chess_english/core/services/settings_controller.dart';
import 'package:chess_english/core/services/sound_service.dart';
import 'package:chess_english/core/services/task_picker.dart';
import 'package:chess_english/core/db/app_database.dart';
import 'package:chess_english/core/repositories/progress_repository.dart';
import 'package:chess_english/core/repositories/srs_repository.dart';
import 'package:chess_english/core/repositories/stats_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  final database = AppDatabase(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  await database.open();
  return database;
}

Word testWord(
  String id,
  String en,
  String ru,
  String lessonId, {
  CefrLevel level = CefrLevel.a1,
}) {
  return Word(
    id: id,
    en: en,
    ru: ru,
    transcription: '/test/',
    partOfSpeech: 'noun',
    exampleEn: 'Example with $en.',
    exampleRu: 'Пример с $ru.',
    lessonId: lessonId,
    level: level,
  );
}

Lesson testLesson({
  required String id,
  required int order,
  required CefrLevel level,
  required List<String> vocabularyIds,
}) {
  return Lesson(
    id: id,
    order: order,
    level: level,
    title: 'Урок $order',
    summary: 'Тестовый урок',
    theory: const <TheoryBlock>[
      TheoryBlock(type: TheoryBlockType.text, content: 'Текст урока'),
    ],
    vocabularyIds: vocabularyIds,
    exercises: const <Exercise>[
      Exercise(
        id: 'ex_test',
        type: ExerciseType.multipleChoice,
        prompt: 'Выбери',
        hint: 'Подсказка',
        options: <String>['a', 'b', 'c'],
      ),
    ],
  );
}

ContentRepository testContent({bool twoLessons = true}) {
  final words = <Word>[
    testWord('w1', 'one', 'один', 'l1'),
    testWord('w2', 'two', 'два', 'l1'),
    testWord('w3', 'three', 'три', 'l1'),
    if (twoLessons) ...<Word>[
      testWord('w4', 'four', 'четыре', 'l2', level: CefrLevel.a2),
      testWord('w5', 'five', 'пять', 'l2', level: CefrLevel.a2),
      testWord('w6', 'six', 'шесть', 'l2', level: CefrLevel.a2),
    ],
  ];
  return ContentRepository(
    lessonPack: LessonPack(
      version: 1,
      plannedTotal: 160,
      lessons: <Lesson>[
        testLesson(
          id: 'l1',
          order: 1,
          level: CefrLevel.a1,
          vocabularyIds: const <String>['w1', 'w2', 'w3'],
        ),
        if (twoLessons)
          testLesson(
            id: 'l2',
            order: 2,
            level: CefrLevel.a2,
            vocabularyIds: const <String>['w4', 'w5', 'w6'],
          ),
      ],
    ),
    vocabularyPack: VocabularyPack(version: 1, words: words),
  );
}

Future<AppServices> buildTestServices({
  ContentRepository? content,
  bool completeFirstLesson = false,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();
  final database = await openTestDatabase();
  final actualContent = content ?? await ContentRepository.loadFromAssets();
  final adaptive = AdaptiveStore(prefs);
  final settings = SettingsController(prefs);
  final srs = SrsRepository(database);
  final progress = ProgressRepository(database);
  final stats = StatsRepository(database);
  if (completeFirstLesson && actualContent.lessons.isNotEmpty) {
    await progress.saveLessonResult(
      lessonId: actualContent.lessons.first.id,
      exercisesOk: 1,
      exercisesAll: 1,
    );
  }
  return AppServices(
    database: database,
    content: actualContent,
    progress: progress,
    srs: srs,
    stats: stats,
    adaptive: adaptive,
    settings: settings,
    sound: SoundService(),
    taskPicker: TaskPicker(
      content: actualContent,
      srs: srs,
      progress: progress,
      adaptive: adaptive,
    ),
  );
}

