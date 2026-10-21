import 'package:chess_english/core/models/cefr_level.dart';
import 'package:chess_english/core/models/lesson.dart';
import 'package:chess_english/core/models/word.dart';
import 'package:chess_english/core/repositories/content_repository.dart';
import 'package:chess_english/core/utils/answer_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('assets соответствуют контракту: 160 уроков, 642 слова, 800 упражнений',
      () async {
    final content = await ContentRepository.loadFromAssets();
    expect(content.lessons.length, 160);
    expect(content.words.length, 642);
    expect(content.plannedTotal, 160);
    expect(content.readingPassages.length, 5);
    expect(
      content.lessons.fold<int>(
        0,
        (sum, lesson) => sum + lesson.exercises.length,
      ),
      800,
    );
    final levels = <CefrLevel, int>{};
    for (final lesson in content.lessons) {
      levels.update(lesson.level, (value) => value + 1, ifAbsent: () => 1);
      expect(lesson.vocabularyIds.length, inInclusiveRange(3, 20));
      expect(lesson.exercises.length, inInclusiveRange(3, 5));
      expect(lesson.theory, isNotEmpty);
    }
    expect(levels[CefrLevel.a1], 40);
    expect(levels[CefrLevel.a2], 40);
    expect(levels[CefrLevel.b1], 80);
    for (final word in content.words) {
      expect(content.lessonById(word.lessonId), isNotNull);
      expect(word.exampleEn, isNotEmpty);
      expect(word.exampleRu, isNotEmpty);
      expect(word.transcription, startsWith('/'));
      expect(word.transcription, endsWith('/'));
    }
  });

  test('упражнения всех трёх типов проверяют ответ', () async {
    final content = await ContentRepository.loadFromAssets();
    final lesson = content.lessonById('lesson_01')!;
    final fill = lesson.exercises.firstWhere(
      (exercise) => exercise.type == ExerciseType.fillBlank,
    );
    expect(fill.acceptsText('NAME'), isTrue);
    expect(fill.acceptsText(' name '), isTrue);
    expect(fill.acceptsText('first'), isFalse);

    final build = lesson.exercises.firstWhere(
      (exercise) => exercise.type == ExerciseType.buildSentence,
    );
    expect(
      build.acceptsBuiltSentence(<String>['My', 'name', 'is', 'Anna']),
      isTrue,
    );
    expect(
      build.acceptsBuiltSentence(<String>['Anna', 'is', 'my', 'name']),
      isFalse,
    );

    final choice = lesson.exercises.firstWhere(
      (exercise) => exercise.type == ExerciseType.multipleChoice,
    );
    expect(choice.isCorrectIndex(choice.correctIndex), isTrue);
    expect(choice.isCorrectIndex(choice.correctIndex + 1), isFalse);
  });

  test('новый B1-урок содержит теорию, лексику и пять упражнений', () async {
    final content = await ContentRepository.loadFromAssets();
    final lesson = content.lessonById('lesson_081')!;
    expect(lesson.level, CefrLevel.b1);
    expect(lesson.vocabularyIds.length, 4);
    expect(lesson.exercises.length, 5);
    expect(
      lesson.exercises.map((exercise) => exercise.type).toSet(),
      containsAll(<ExerciseType>[
        ExerciseType.multipleChoice,
        ExerciseType.fillBlank,
        ExerciseType.buildSentence,
      ]),
    );
  });

  test('нормализация ответа игнорирует регистр, пробелы и пунктуацию', () {
    expect(
      AnswerChecker.normalize('  How   OLD are you? '),
      'how old are you',
    );
    expect(AnswerChecker.normalize('My name is Anna.'), 'my name is anna');
  });

  test('контент не принимает слово с несуществующим уроком', () {
    expect(
      () => ContentRepository(
        lessonPack: const LessonPack(
          version: 1,
          plannedTotal: 160,
          lessons: <Lesson>[
            Lesson(
              id: 'l1',
              order: 1,
              level: CefrLevel.a1,
              title: 'T',
              summary: 'S',
              theory: <TheoryBlock>[],
              vocabularyIds: <String>['missing'],
              exercises: <Exercise>[],
            ),
          ],
        ),
        vocabularyPack: testPackWithNoWords(),
      ),
      throwsFormatException,
    );
  });
}

VocabularyPack testPackWithNoWords() => const VocabularyPack(
      version: 1,
      words: <Word>[],
    );

