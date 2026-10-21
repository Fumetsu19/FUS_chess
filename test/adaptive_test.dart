import 'package:chess_english/core/services/adaptive_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 1, 10, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('журнал ошибок учитывает только последние 7 дней', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = AdaptiveStore(prefs);
    await store.recordWrong('w1', now: now.subtract(const Duration(days: 2)));
    await store.recordWrong('w1', now: now.subtract(const Duration(days: 8)));
    expect(await store.wrongCount('w1', now: now), 1);
    final counts = await store.wrongCounts(now: now);
    expect(counts['w1'], 1);
  });

  test('5 верных MC подряд включают fill_blank-режим урока', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = AdaptiveStore(prefs);
    for (var i = 0; i < 4; i++) {
      await store.recordMcResult('lesson_01', firstTryCorrect: true);
    }
    expect(await store.prefersFillBlank('lesson_01'), isFalse);
    await store.recordMcResult('lesson_01', firstTryCorrect: true);
    expect(await store.prefersFillBlank('lesson_01'), isTrue);
    expect(await store.mcStreak('lesson_01'), 5);
  });

  test('ошибка сбрасывает MC-серию', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = AdaptiveStore(prefs);
    await store.recordMcResult('lesson_01', firstTryCorrect: true);
    await store.recordMcResult('lesson_01', firstTryCorrect: true);
    await store.recordMcResult('lesson_01', firstTryCorrect: false);
    expect(await store.mcStreak('lesson_01'), 0);
  });
}
