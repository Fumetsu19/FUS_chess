import 'lesson.dart';
import 'reading.dart';

enum B1Section {
  grammar('Грамматика'),
  vocabulary('Лексика'),
  writing('Письмо'),
  reading('Чтение');

  const B1Section(this.label);

  final String label;
}

class B1TestQuestion {
  const B1TestQuestion({
    required this.id,
    required this.section,
    this.exercise,
    this.reading,
    this.lessonId,
  });

  final String id;
  final B1Section section;
  final Exercise? exercise;
  final ReadingPassage? reading;
  final String? lessonId;

  String get prompt => reading?.question ?? exercise!.prompt;

  String get context => reading?.text ?? '';

  List<String> get options =>
      reading?.options ?? exercise?.options ?? const <String>[];

  ExerciseType? get exerciseType => exercise?.type;

  bool isCorrectIndex(int index) {
    final readingTask = reading;
    if (readingTask != null) return index == readingTask.correct;
    return exercise!.isCorrectIndex(index);
  }

  bool acceptsText(String value) => exercise?.acceptsText(value) ?? false;

  bool acceptsBuiltSentence(List<String> words) =>
      exercise?.acceptsBuiltSentence(words) ?? false;
}

class B1TestResult {
  const B1TestResult({
    required this.total,
    required this.correct,
    required this.correctBySection,
    required this.totalBySection,
    required this.weakLessonIds,
  });

  final int total;
  final int correct;
  final Map<B1Section, int> correctBySection;
  final Map<B1Section, int> totalBySection;
  final List<String> weakLessonIds;

  double get score => total == 0 ? 0 : correct / total;

  int get percent => (score * 100).round();

  bool get passed => score >= B1TestPolicy.passThreshold;

  int sectionCorrect(B1Section section) => correctBySection[section] ?? 0;

  int sectionTotal(B1Section section) => totalBySection[section] ?? 0;
}

class B1TestPolicy {
  const B1TestPolicy._();

  static const totalQuestions = 30;
  static const passThreshold = 0.7;

  static int get passScore => (totalQuestions * passThreshold).ceil();

  static const canDo = <String>[
    'Понимаю основные идеи ясных текстов на знакомые темы.',
    'Могу справиться с большинством ситуаций в поездке.',
    'Могу кратко объяснить опыт, планы и мнение.',
    'Понимаю ключевую грамматику уровня B1 в контексте.',
    'Могу написать связное простое предложение по смыслу.',
  ];
}
