import 'package:chess_english/core/services/stockfish_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UCI bestmove парсится, включая превращение', () {
    final normal = UciParser.parseBestMove('bestmove e2e4 ponder e7e5');
    expect(normal, isNotNull);
    expect(normal!.from, 'e2');
    expect(normal.to, 'e4');
    expect(normal.promotion, isNull);
    expect(normal.uci, 'e2e4');

    final promotion = UciParser.parseBestMove('bestmove a7a8q');
    expect(promotion, isNotNull);
    expect(promotion!.promotion, 'q');
    expect(promotion.uci, 'a7a8q');
  });

  test('UCI bestmove отклоняет none и мусор', () {
    expect(UciParser.parseBestMove('bestmove (none)'), isNull);
    expect(UciParser.parseBestMove('bestmove 0000'), isNull);
    expect(UciParser.parseBestMove('info depth 10'), isNull);
    expect(UciParser.parseBestMove('bestmove z9z9'), isNull);
  });
}
