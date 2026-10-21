import 'dart:math';

import '../models/b1_test.dart';
import '../models/cefr_level.dart';
import '../models/lesson.dart';
import '../models/reading.dart';
import '../repositories/content_repository.dart';

class B1TestBuilder {
  const B1TestBuilder({this.random});

  final Random? random;

  List<B1TestQuestion> build(ContentRepository content) {
    final rng = random ?? Random();
    final b1Lessons = content.lessons
        .where((lesson) => lesson.level == CefrLevel.b1)
        .toList(growable: false);
    if (b1Lessons.isEmpty) {
      throw StateError('В контенте нет уроков B1');
    }

    final grammar = <Exercise>[];
    final vocabulary = <Exercise>[];
    final fills = <Exercise>[];
    final builds = <Exercise>[];
    for (final lesson in b1Lessons) {
      for (final exercise in lesson.exercises) {
        if (exercise.type == ExerciseType.buildSentence) {
          builds.add(exercise);
        } else if (exercise.type == ExerciseType.fillBlank) {
          fills.add(exercise);
        } else if (exercise.id.endsWith('_01')) {
          vocabulary.add(exercise);
        } else {
          grammar.add(exercise);
        }
      }
    }

    final usedPrompts = <String>{};
    final questions = <B1TestQuestion>[];
    final sections = <B1Section, List<Exercise>>{
      B1Section.grammar: _sample(grammar, 10, rng, usedPrompts),
      B1Section.vocabulary: _sample(vocabulary, 5, rng, usedPrompts),
      B1Section.writing: _sample(builds, 5, rng, usedPrompts),
    };
    for (final entry in sections.entries) {
      for (final exercise in entry.value) {
        questions.add(
          B1TestQuestion(
            id: '${entry.key.name}_${exercise.id}',
            section: entry.key,
            exercise: exercise,
            lessonId: _lessonIdForExercise(content, exercise.id),
          ),
        );
      }
    }

    final fillSample = _sample(fills, 5, rng, usedPrompts);
    for (final exercise in fillSample) {
      questions.add(
        B1TestQuestion(
          id: 'fill_${exercise.id}',
          section: exercise.id.endsWith('_03')
              ? B1Section.vocabulary
              : B1Section.grammar,
          exercise: exercise,
          lessonId: _lessonIdForExercise(content, exercise.id),
        ),
      );
    }

    final reading = _sampleReading(
      content.readingPassages.where((item) => item.level == 'B1').toList(),
      5,
      rng,
    );
    for (final passage in reading) {
      questions.add(
        B1TestQuestion(
          id: 'reading_${passage.id}',
          section: B1Section.reading,
          reading: passage,
        ),
      );
    }

    // На случай расширения/ручного контента: добираем недостающие вопросы
    // из любых B1-упражнений, не повторяя формулировки.
    if (questions.length < B1TestPolicy.totalQuestions) {
      final all = <Exercise>[...grammar, ...vocabulary, ...fills, ...builds];
      all.shuffle(rng);
      for (final exercise in all) {
        if (questions.length >= B1TestPolicy.totalQuestions) break;
        if (!usedPrompts.add(_exerciseKey(exercise))) continue;
        final section = exercise.type == ExerciseType.buildSentence
            ? B1Section.writing
            : exercise.id.endsWith('_03')
                ? B1Section.vocabulary
                : B1Section.grammar;
        questions.add(
          B1TestQuestion(
            id: 'extra_${exercise.id}',
            section: section,
            exercise: exercise,
            lessonId: _lessonIdForExercise(content, exercise.id),
          ),
        );
      }
    }

    questions.shuffle(rng);
    return questions;
  }

  List<Exercise> _sample(
    List<Exercise> source,
    int count,
    Random rng,
    Set<String> usedPrompts,
  ) {
    final pool = List<Exercise>.of(source)..shuffle(rng);
    final result = <Exercise>[];
    for (final exercise in pool) {
      if (result.length >= count) break;
      if (usedPrompts.add(_exerciseKey(exercise))) result.add(exercise);
    }
    return result;
  }

  String _exerciseKey(Exercise exercise) {
    return '${exercise.prompt}|${exercise.answer}';
  }

  List<ReadingPassage> _sampleReading(
    List<ReadingPassage> source,
    int count,
    Random rng,
  ) {
    final pool = List<ReadingPassage>.of(source)..shuffle(rng);
    return pool.take(count).toList(growable: false);
  }

  String? _lessonIdForExercise(ContentRepository content, String exerciseId) {
    for (final lesson in content.lessons) {
      if (lesson.exercises.any((exercise) => exercise.id == exerciseId)) {
        return lesson.id;
      }
    }
    return null;
  }
}
