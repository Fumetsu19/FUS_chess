import 'package:chess_english/app.dart';
import 'package:chess_english/core/models/cefr_level.dart';
import 'package:chess_english/core/repositories/content_repository.dart';
import 'package:chess_english/features/b1_test/b1_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('главный экран показывает прогресс и все разделы',
      (tester) async {
    final services = await tester.runAsync(() async {
      final content = await ContentRepository.loadFromAssets();
      return buildTestServices(content: content);
    });
    expect(services, isNotNull);
    addTearDown(() async {
      await tester.runAsync(services!.dispose);
    });

    await tester.pumpWidget(ChessEnglishApp(services: services!));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Твой следующий ход'), findsOneWidget);
    expect(find.text('Играть'), findsOneWidget);
    expect(find.text('A1 → B1'), findsOneWidget);
    expect(find.textContaining('К повторению'), findsOneWidget);

    for (final label in <String>[
      'Уроки',
      'Тест B1',
      'Словарь',
      'Перестрелка',
      'Свободный режим',
      'Настройки',
    ]) {
      var attempts = 0;
      while (find.text(label).evaluate().isEmpty && attempts < 12) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -260));
        await tester.pump(const Duration(milliseconds: 250));
        attempts++;
      }
      expect(find.text(label), findsOneWidget, reason: label);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('B1-тест закрыт до завершения всех 80 уроков B1',
      (tester) async {
    final services = await tester.runAsync(() async {
      final content = await ContentRepository.loadFromAssets();
      return buildTestServices(content: content);
    });
    expect(services, isNotNull);
    addTearDown(() async {
      await tester.runAsync(services!.dispose);
    });

    await tester.pumpWidget(
      MaterialApp(home: B1TestScreen(services: services!)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Тест B1 пока закрыт'), findsOneWidget);
    expect(find.textContaining('0 / 80'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('B1-тест открывается после всех 80 B1-уроков',
      (tester) async {
    final services = await tester.runAsync(() async {
      final content = await ContentRepository.loadFromAssets();
      return buildTestServices(content: content);
    });
    expect(services, isNotNull);
    addTearDown(() async {
      await tester.runAsync(services!.dispose);
    });
    await tester.runAsync(() async {
      for (final lesson in services!.content.lessons
          .where((lesson) => lesson.level == CefrLevel.b1)) {
        await services.progress.saveLessonResult(
          lessonId: lesson.id,
          exercisesOk: 5,
          exercisesAll: 5,
        );
      }
    });

    await tester.pumpWidget(
      MaterialApp(home: B1TestScreen(services: services!)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Проверка уровня B1'), findsOneWidget);

    var attempts = 0;
    while (find.text('Начать тест').evaluate().isEmpty && attempts < 10) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 200));
      attempts++;
    }
    expect(find.text('Начать тест'), findsOneWidget);

    await tester.tap(find.text('Начать тест'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('ВОПРОС 1 ИЗ 30'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
