import 'package:chess_english/core/models/engine_difficulty.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('уровни сдвинуты: бывший лёгкий стал средним, лёгкий ещё мягче', () {
    expect(EngineDifficulty.medium.skillLevel, 0);
    expect(EngineDifficulty.medium.depth, 1);
    expect(EngineDifficulty.medium.moveTimeMs, 80);
    expect(EngineDifficulty.easy.randomMoveChance, greaterThan(0.3));
    expect(EngineDifficulty.easy.moveTimeMs, lessThan(EngineDifficulty.medium.moveTimeMs));
    expect(EngineDifficulty.hard.skillLevel, 8);
    expect(EngineDifficulty.expert.skillLevel, 18);
  });
}
