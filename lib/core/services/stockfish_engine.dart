import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:multistockfish/multistockfish.dart';

import '../models/engine_difficulty.dart';

class UciMove {
  const UciMove({
    required this.from,
    required this.to,
    this.promotion,
  });

  final String from;
  final String to;
  final String? promotion;

  String get uci => '$from$to${promotion ?? ''}';
}

class UciParser {
  const UciParser._();

  static final RegExp _movePattern = RegExp(r'^[a-h][1-8][a-h][1-8][qrbn]?$');

  static UciMove? parseBestMove(String line) {
    final parts = line.trim().split(RegExp(r'\s+'));
    if (parts.length < 2 || parts.first != 'bestmove') return null;
    final raw = parts[1];
    if (!_movePattern.hasMatch(raw)) return null;
    return UciMove(
      from: raw.substring(0, 2),
      to: raw.substring(2, 4),
      promotion: raw.length > 4 ? raw.substring(4, 5) : null,
    );
  }
}

class StockfishEngine {
  StockfishEngine();

  Stockfish? _engine;
  StreamSubscription<String>? _subscription;
  Future<bool>? _starting;
  Completer<String?>? _pending;
  bool _failed = false;
  bool _busy = false;
  bool _disposed = false;

  bool get failed => _failed;

  Future<bool> start() {
    if (_disposed || _failed) return Future<bool>.value(false);
    if (_engine != null) return Future<bool>.value(true);
    return _starting ??= _startInternal().whenComplete(() {
      _starting = null;
    });
  }

  Future<bool> _startInternal() async {
    try {
      final engine = await Stockfish.create();
      if (_disposed) {
        await engine.dispose();
        return false;
      }
      _engine = engine;
      _subscription = engine.stdout.listen(_onLine);
      _send('setoption name Threads value 1');
      _send('setoption name Hash value 16');
      _send('ucinewgame');
      return true;
    } catch (error, stackTrace) {
      _failed = true;
      debugPrint('Stockfish: не удалось запустить движок: $error\n$stackTrace');
      return false;
    }
  }

  Future<String?> findBestMove({
    required String fen,
    required EngineDifficulty difficulty,
  }) {
    return _find(
      fen: fen,
      skillLevel: difficulty.skillLevel,
      depth: difficulty.depth,
      moveTimeMs: difficulty.moveTimeMs,
    );
  }

  /// Сильный, но быстрый разбор для подсказки игроку.
  Future<String?> findHint({required String fen}) {
    return _find(fen: fen, skillLevel: 20, depth: 8, moveTimeMs: 450);
  }

  Future<String?> _find({
    required String fen,
    required int skillLevel,
    required int depth,
    required int moveTimeMs,
  }) async {
    if (_disposed || _busy) return null;
    if (!await start()) return null;
    _busy = true;
    try {
      _send('setoption name Skill Level value $skillLevel');
      _send('position fen $fen');
      final completer = Completer<String?>();
      _pending = completer;
      _send('go depth $depth movetime $moveTimeMs');
      return await completer.future.timeout(
        Duration(milliseconds: moveTimeMs + 6000),
        onTimeout: () {
          _send('stop');
          return null;
        },
      );
    } catch (error) {
      debugPrint('Stockfish: ошибка запроса хода: $error');
      _failed = true;
      return null;
    } finally {
      _pending = null;
      _busy = false;
    }
  }

  void _onLine(String line) {
    if (!line.startsWith('bestmove')) return;
    final completer = _pending;
    if (completer == null || completer.isCompleted) return;
    final move = UciParser.parseBestMove(line);
    completer.complete(move?.uci);
  }

  void _send(String command) {
    final engine = _engine;
    if (engine == null) return;
    try {
      engine.stdin = command;
    } catch (error) {
      debugPrint('Stockfish: команда не отправлена ($command): $error');
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    final engine = _engine;
    _engine = null;
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    await _subscription?.cancel();
    _subscription = null;
    if (engine != null) {
      try {
        await engine.dispose();
      } catch (error) {
        debugPrint('Stockfish: ошибка при остановке: $error');
      }
    }
  }
}
