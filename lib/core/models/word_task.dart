import 'word.dart';

class WordTask {
  const WordTask({
    required this.word,
    required this.options,
    required this.correctIndex,
    required this.hint,
  });

  final Word word;
  final List<String> options;
  final int correctIndex;
  final String hint;

  bool isCorrectIndex(int index) => index == correctIndex;

  String get correctAnswer => options[correctIndex];
}
