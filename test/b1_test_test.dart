import 'dart:math';

import 'package:chess_english/core/models/b1_test.dart';
import 'package:chess_english/core/repositories/content_repository.dart';
import 'package:chess_english/core/services/b1_test_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('B1-тест собирает 30 вопросов из всех четырёх разделов', () async {
    final content = await ContentRepository.loadFromAssets();
    final questions = B1TestBuilder(random: Random(1)).build(content);
    expect(questions.length, B1TestPolicy.totalQuestions);
    final bySection = <B1Section, int>{};
    for (final question in questions) {
      bySection.update(
        question.section,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      expect(question.prompt, isNotEmpty);
      if (question.reading != null) {
        expect(question.reading!.text, isNotEmpty);
        expect(question.options.length, 3);
      } else {
        expect(question.exercise, isNotNull);
      }
    }
    expect(bySection[B1Section.grammar], greaterThan(0));
    expect(bySection[B1Section.vocabulary], greaterThan(0));
    expect(bySection[B1Section.writing], greaterThan(0));
    expect(bySection[B1Section.reading], 5);
    expect(B1TestPolicy.passScore, 21);
  });

  test('B1-тест не повторяет формулировки заданий', () async {
    final content = await ContentRepository.loadFromAssets();
    final questions = B1TestBuilder(random: Random(42)).build(content);
    final keys = questions
        .where((question) => question.exercise != null)
        .map((question) =>
            '${question.exercise!.prompt}|${question.exercise!.answer}')
        .toList();
    expect(keys.length, keys.toSet().length);
  });

  test('B1TestResult считает порог 70%', () {
    final failed = B1TestResult(
      total: 30,
      correct: 20,
      correctBySection: const <B1Section, int>{},
      totalBySection: const <B1Section, int>{},
      weakLessonIds: const <String>[],
    );
    final passed = B1TestResult(
      total: 30,
      correct: 21,
      correctBySection: const <B1Section, int>{},
      totalBySection: const <B1Section, int>{},
      weakLessonIds: const <String>[],
    );
    expect(failed.passed, isFalse);
    expect(passed.passed, isTrue);
  });
}
