import '../utils/answer_checker.dart';
import 'cefr_level.dart';

enum TheoryBlockType {
  text('text'),
  example('example'),
  note('note');

  const TheoryBlockType(this.wire);

  final String wire;

  static TheoryBlockType fromString(String value) {
    return TheoryBlockType.values.firstWhere(
      (type) => type.wire == value,
      orElse: () => throw FormatException('Неизвестный тип блока теории: $value'),
    );
  }
}

class TheoryBlock {
  const TheoryBlock({required this.type, required this.content});

  final TheoryBlockType type;
  final String content;

  factory TheoryBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    final content = json['content'];
    if (type is! String || content is! String || content.trim().isEmpty) {
      throw const FormatException('theory block: нужны type и content');
    }
    return TheoryBlock(
      type: TheoryBlockType.fromString(type),
      content: content,
    );
  }
}

enum ExerciseType {
  multipleChoice('multiple_choice', 'Выбери ответ'),
  fillBlank('fill_blank', 'Заполни пропуск'),
  buildSentence('build_sentence', 'Собери предложение');

  const ExerciseType(this.wire, this.label);

  final String wire;
  final String label;

  static ExerciseType fromString(String value) {
    return ExerciseType.values.firstWhere(
      (type) => type.wire == value,
      orElse: () => throw FormatException('Неизвестный тип упражнения: $value'),
    );
  }
}

class Exercise {
  const Exercise({
    required this.id,
    required this.type,
    required this.prompt,
    required this.hint,
    this.options = const <String>[],
    this.correctIndex = 0,
    this.answer = '',
    this.accepted = const <String>[],
    this.words = const <String>[],
  });

  final String id;
  final ExerciseType type;
  final String prompt;
  final String hint;
  final List<String> options;
  final int correctIndex;
  final String answer;
  final List<String> accepted;
  final List<String> words;

  bool get isMultipleChoice => type == ExerciseType.multipleChoice;

  bool isCorrectIndex(int index) => index == correctIndex;

  bool acceptsText(String value) {
    if (type == ExerciseType.multipleChoice) {
      return int.tryParse(value.trim()) == correctIndex;
    }
    final candidates = <String>[answer, ...accepted];
    return candidates.any(
      (candidate) => AnswerChecker.normalize(candidate) ==
          AnswerChecker.normalize(value),
    );
  }

  bool acceptsBuiltSentence(List<String> selected) {
    return AnswerChecker.normalize(selected.join(' ')) ==
        AnswerChecker.normalize(answer);
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('exercise: поле "$key" обязательно');
      }
      return value;
    }

    final type = ExerciseType.fromString(read('type'));
    final id = read('id');
    final prompt = read('prompt');
    final hint = read('hint');
    switch (type) {
      case ExerciseType.multipleChoice:
        final options = json['options'];
        final correct = json['correct'];
        if (options is! List ||
            options.length < 2 ||
            correct is! num ||
            correct.toInt() < 0 ||
            correct.toInt() >= options.length) {
          throw FormatException('exercise $id: некорректные options/correct');
        }
        return Exercise(
          id: id,
          type: type,
          prompt: prompt,
          hint: hint,
          options: options.map((item) => '$item').toList(growable: false),
          correctIndex: correct.toInt(),
        );
      case ExerciseType.fillBlank:
        final answer = read('answer');
        final accepted = json['accepted'];
        return Exercise(
          id: id,
          type: type,
          prompt: prompt,
          hint: hint,
          answer: answer,
          accepted: accepted is List
              ? accepted.map((item) => '$item').toList(growable: false)
              : const <String>[],
        );
      case ExerciseType.buildSentence:
        final words = json['words'];
        final answer = read('answer');
        if (words is! List || words.length < 2) {
          throw FormatException('exercise $id: нужен массив words');
        }
        return Exercise(
          id: id,
          type: type,
          prompt: prompt,
          hint: hint,
          answer: answer,
          words: words.map((item) => '$item').toList(growable: false),
        );
    }
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.order,
    required this.level,
    required this.title,
    required this.summary,
    required this.theory,
    required this.vocabularyIds,
    required this.exercises,
  });

  final String id;
  final int order;
  final CefrLevel level;
  final String title;
  final String summary;
  final List<TheoryBlock> theory;
  final List<String> vocabularyIds;
  final List<Exercise> exercises;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('lesson: поле "$key" обязательно');
      }
      return value;
    }

    final order = json['order'];
    final theory = json['theory'];
    final vocabularyIds = json['vocabulary_ids'];
    final exercises = json['exercises'];
    if (order is! num ||
        theory is! Map ||
        vocabularyIds is! List ||
        exercises is! List) {
      throw FormatException('lesson ${json['id']}: нарушена схема');
    }
    final blocks = theory['blocks'];
    if (blocks is! List) {
      throw FormatException('lesson ${json['id']}: нет theory.blocks');
    }
    return Lesson(
      id: read('id'),
      order: order.toInt(),
      level: CefrLevel.fromString(read('level')),
      title: read('title'),
      summary: read('summary'),
      theory: blocks
          .map((item) => TheoryBlock.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      vocabularyIds:
          vocabularyIds.map((item) => '$item').toList(growable: false),
      exercises: exercises
          .map((item) => Exercise.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}

class LessonPack {
  const LessonPack({
    required this.version,
    required this.plannedTotal,
    required this.lessons,
  });

  final int version;
  final int plannedTotal;
  final List<Lesson> lessons;

  factory LessonPack.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'];
    if (rawLessons is! List) {
      throw const FormatException('lessons: отсутствует массив lessons');
    }
    final lessons = rawLessons
        .map((item) => Lesson.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    final planned = (json['planned_total'] as num?)?.toInt() ?? lessons.length;
    return LessonPack(
      version: (json['version'] as num?)?.toInt() ?? 1,
      plannedTotal: planned < lessons.length ? lessons.length : planned,
      lessons: lessons,
    );
  }
}
