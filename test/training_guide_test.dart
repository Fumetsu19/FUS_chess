import 'package:chess_english/core/theme/app_theme.dart';
import 'package:chess_english/features/free_play/training_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('обучение показывает все фигуры и особые правила',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: SingleChildScrollView(child: TrainingGuideContent()),
        ),
      ),
    );
    for (final name in <String>[
      'Пешка',
      'Конь',
      'Слон',
      'Ладья',
      'Ферзь',
      'Король',
      'Рокировка',
      'Взятие на проходе',
      'Превращение',
      'Шах и мат',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });
}
