import 'dart:async';
import 'dart:math';

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

import '../../core/models/engine_difficulty.dart';
import '../../core/models/game_summary.dart';
import '../../core/models/lesson.dart';
import '../../core/models/word_task.dart';
import '../../core/services/app_services.dart';
import '../../core/services/sound_service.dart';
import '../../core/services/stockfish_engine.dart';

enum GamePhase {
  loadingTask,
  taskActive,
  awaitingMove,
  engineThinking,
  finished,
}

class GameController extends ChangeNotifier {
  factory GameController({
    required AppServices services,
    required int sessionId,
    required bool isLessonGame,
    Lesson? lesson,
    bool trainingMode = false,
    int initialTasksTotal = 0,
    int initialTasksFirstTry = 0,
    int initialTasksSolved = 0,
    Random? random,
  }) {
    return GameController._(
      services,
      sessionId,
      isLessonGame,
      lesson,
      trainingMode,
      initialTasksTotal,
      initialTasksFirstTry,
      initialTasksSolved,
      random ?? Random(),
    );
  }

  GameController._(
    this._services,
    this.sessionId,
    this.isLessonGame,
    this.lesson,
    this.trainingMode,
    int initialTasksTotal,
    int initialTasksFirstTry,
    int initialTasksSolved,
    this._random,
  )   : _tasksTotal = initialTasksTotal,
        _tasksFirstTry = initialTasksFirstTry,
        _tasksSolved = initialTasksSolved;

  final AppServices _services;
  final int sessionId;
  final bool isLessonGame;
  final bool trainingMode;
  final Lesson? lesson;
  final Random _random;

  final ChessBoardController board = ChessBoardController();
  final StockfishEngine _engine = StockfishEngine();

  GamePhase _phase = GamePhase.loadingTask;
  WordTask? _task;
  int _attempts = 0;
  int? _wrongOptionIndex;
  bool _taskCompleted = false;
  bool _taskSolved = false;
  bool _currentTaskFirstTry = false;
  bool _hintVisible = false;
  bool _engineUnavailable = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _hintLoading = false;
  UciMove? _hintMove;
  String? _hintText;
  String? _notice;

  int _tasksTotal;
  int _tasksSolved;
  int _tasksFirstTry;
  int _movesMade = 0;
  final List<String> _weakWordOrder = <String>[];
  final Set<String> _usedTaskWordIds = <String>{};

  int _lastMoveCount = 0;
  bool _applyingEngineMove = false;
  String? _lastWordId;
  GameSummary? _summary;
  bool _finishing = false;

  int get attempts => _attempts;
  int get attemptsLeft => max(0, 3 - _attempts);
  WordTask? get task => _task;
  GamePhase get phase => _phase;
  GameSummary? get summary => _summary;
  bool get hintVisible => _hintVisible;
  bool get taskCompleted => _taskCompleted;
  bool get taskSolved => _taskSolved;
  bool get currentTaskFirstTry => _currentTaskFirstTry;
  bool get engineUnavailable => _engineUnavailable;
  int? get wrongOptionIndex => _wrongOptionIndex;
  int get tasksTotal => _tasksTotal;
  int get tasksSolved => _tasksSolved;
  int get tasksFirstTry => _tasksFirstTry;
  int get movesMade => _movesMade;
  int get lastMoveCount => board.moveCount;
  bool get isLessonGameMode => isLessonGame;
  bool get isTraining => trainingMode;
  UciMove? get hintMove => _hintMove;
  String? get hintText => _hintText;
  bool get hintLoading => _hintLoading;
  String? get notice => _notice;
  EngineDifficulty get difficulty =>
      trainingMode ? EngineDifficulty.easy : _services.settings.difficulty;

  bool get canMove =>
      _phase == GamePhase.awaitingMove &&
      board.playerColor == PlayerColor.white &&
      !board.isGameOver &&
      !_hintLoading;

  bool get canAnswerTask => _phase == GamePhase.taskActive && !_taskCompleted;

  bool get hintsAvailable =>
      (trainingMode || isLessonGame || difficulty.isBeginner) &&
      _phase == GamePhase.awaitingMove &&
      !board.isGameOver;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    board.addListener(_onBoardChanged);
    _lastMoveCount = board.moveCount;
    unawaited(
      _engine.start().then((started) {
        if (!started && !_disposed) {
          _engineUnavailable = true;
          _notify();
        }
      }),
    );
    if (!isLessonGame || lesson == null) {
      _phase = GamePhase.awaitingMove;
      _notify();
      if (trainingMode) unawaited(requestHint());
      return;
    }
    await _loadNextTask();
  }

  Future<void> _loadNextTask() async {
    if (_disposed) return;
    _phase = GamePhase.loadingTask;
    _task = null;
    _attempts = 0;
    _wrongOptionIndex = null;
    _taskCompleted = false;
    _taskSolved = false;
    _currentTaskFirstTry = false;
    _hintVisible = false;
    _notify();
    final next = await _safePickTask();
    if (_disposed) return;
    if (next == null) {
      _phase = GamePhase.awaitingMove;
      _notify();
      if (trainingMode) unawaited(requestHint());
      return;
    }
    _task = next;
    _lastWordId = next.word.id;
    _usedTaskWordIds.add(next.word.id);
    _phase = GamePhase.taskActive;
    _notify();
  }

  Future<WordTask?> _safePickTask() async {
    try {
      return await _services.taskPicker.pickForMove(
        lesson: lesson!,
        lastWordId: _lastWordId,
        excludeWordIds: _usedTaskWordIds,
      );
    } catch (error, stackTrace) {
      debugPrint('TaskPicker: не удалось подобрать задачу: $error\n$stackTrace');
      return null;
    }
  }

  void showHint() {
    if (!canAnswerTask || _hintVisible) return;
    _hintVisible = true;
    _notify();
  }

  Future<void> answerWord(int index) async {
    final currentTask = _task;
    if (!canAnswerTask || currentTask == null) return;
    _wrongOptionIndex = null;
    if (currentTask.isCorrectIndex(index)) {
      _taskSolved = true;
      _taskCompleted = true;
      _currentTaskFirstTry = _attempts == 0;
      _notify();
      await _completeTask(correct: true, firstTry: _attempts == 0);
      return;
    }

    _attempts++;
    _wrongOptionIndex = index;
    await _services.adaptive.recordWrong(currentTask.word.id);
    if (_attempts >= 3) {
      _taskSolved = false;
      _taskCompleted = true;
      _notify();
      await _completeTask(correct: false, firstTry: false);
      return;
    }
    _notify();
  }

  Future<void> _completeTask({
    required bool correct,
    required bool firstTry,
  }) async {
    final currentTask = _task;
    if (currentTask == null) return;
    _tasksTotal++;
    if (correct) {
      _tasksSolved++;
      _weakWordOrder.remove(currentTask.word.id);
    } else {
      if (!_weakWordOrder.contains(currentTask.word.id)) {
        _weakWordOrder.add(currentTask.word.id);
      }
    }
    if (firstTry) _tasksFirstTry++;
    try {
      await _services.stats.addTask(sessionId, firstTry: firstTry);
      await _services.srs.recordAttempt(
        currentTask.word.id,
        correct: correct,
      );
    } catch (error, stackTrace) {
      debugPrint('GameController: не удалось сохранить задачу: $error\n$stackTrace');
    }
    _notify();
  }

  void continueToBoard() {
    if (!_taskCompleted || _phase != GamePhase.taskActive) return;
    _phase = GamePhase.awaitingMove;
    _task = null;
    _taskCompleted = false;
    _notify();
  }

  Future<void> requestHint() async {
    if (_disposed ||
        _hintLoading ||
        _phase != GamePhase.awaitingMove ||
        board.isGameOver) {
      return;
    }
    _hintLoading = true;
    _hintMove = null;
    _hintText = 'Ищу хороший ход…';
    _notify();
    final best = await _engine.findHint(fen: board.fen);
    if (_disposed || _phase != GamePhase.awaitingMove || board.isGameOver) {
      return;
    }
    final parsed = best == null ? null : UciParser.parseBestMove('bestmove $best');
    if (parsed != null) {
      _setHint(parsed);
    } else {
      _setHint(_localHint() ?? const UciMove(from: 'e2', to: 'e4'));
    }
    _hintLoading = false;
    _notify();
  }

  void _setHint(UciMove move) {
    _hintMove = move;
    final target = board.game.get(move.to);
    if (target != null) {
      _hintText =
          'Подсказка: ${move.from} → ${move.to}. Можно забрать фигуру соперника.';
    } else {
      _hintText =
          'Подсказка: ${move.from} → ${move.to}. Попробуй этот ход и посмотри, что изменится.';
    }
  }

  UciMove? _localHint() {
    final moves = board.game.generate_moves();
    if (moves.isEmpty) return null;
    moves.sort((a, b) {
      final aCapture = a.captured == null ? 0 : 1;
      final bCapture = b.captured == null ? 0 : 1;
      return bCapture.compareTo(aCapture);
    });
    final move = moves.first;
    return UciMove(
      from: move.fromAlgebraic,
      to: move.toAlgebraic,
      promotion: move.promotion?.name.substring(0, 1),
    );
  }

  void _onBoardChanged() {
    if (_disposed) return;
    if (board.moveCount <= _lastMoveCount) return;
    _lastMoveCount = board.moveCount;
    _playMoveSound();
    if (_applyingEngineMove) {
      _applyingEngineMove = false;
      final move = board.history.last.move;
      if ((move.flags & chess.Chess.BITS_KSIDE_CASTLE) != 0 ||
          (move.flags & chess.Chess.BITS_QSIDE_CASTLE) != 0) {
        _notice =
            'Соперник сделал рокировку: король и ладья поменялись местами.';
      }
      _notify();
      unawaited(_afterEngineMove());
      return;
    }
    unawaited(_afterPlayerMove());
  }

  Future<void> _afterPlayerMove() async {
    if (_phase == GamePhase.finished) return;
    _movesMade++;
    _hintMove = null;
    _hintText = null;
    _hintLoading = false;
    _notice = null;
    if (board.isGameOver) {
      try {
        await _services.stats.addPlayerMove(sessionId);
      } catch (error) {
        debugPrint('GameController: ход не сохранён: $error');
      }
      await _finishFromBoard();
      return;
    }
    _phase = GamePhase.engineThinking;
    _notify();
    try {
      await _services.stats.addPlayerMove(sessionId);
    } catch (error) {
      debugPrint('GameController: ход не сохранён: $error');
    }
    await _playEngineMove();
  }

  Future<void> _afterEngineMove() async {
    if (_disposed || _phase == GamePhase.finished) return;
    if (board.isGameOver) {
      await _finishFromBoard();
      return;
    }
    await _loadNextTask();
  }

  Future<void> _playEngineMove() async {
    if (_disposed || board.isGameOver) return;
    final difficulty = this.difficulty;
    if (difficulty.randomMoveChance > 0 &&
        _random.nextDouble() < difficulty.randomMoveChance) {
      await _playRandomFallback();
      return;
    }
    final best = await _engine.findBestMove(
      fen: board.fen,
      difficulty: difficulty,
    );
    if (_disposed || _phase != GamePhase.engineThinking) return;
    if (best == null) {
      _engineUnavailable = true;
      await _playRandomFallback();
      return;
    }
    final parsed = UciParser.parseBestMove('bestmove $best');
    if (parsed == null || !_applyMove(parsed)) {
      _engineUnavailable = true;
      await _playRandomFallback();
    }
  }

  bool _applyMove(UciMove move) {
    _applyingEngineMove = true;
    final accepted = board.makeMove(
      from: move.from,
      to: move.to,
      promotion: move.promotion,
    );
    if (!accepted) _applyingEngineMove = false;
    return accepted;
  }

  Future<void> _playRandomFallback() async {
    final moves = board.game.generate_moves();
    if (moves.isEmpty) {
      await _finishFromBoard();
      return;
    }
    _notify();
    final move = moves[_random.nextInt(moves.length)];
    final promotion = move.promotion?.name.substring(0, 1);
    _applyingEngineMove = true;
    final accepted = board.makeMove(
      from: move.fromAlgebraic,
      to: move.toAlgebraic,
      promotion: promotion,
    );
    if (!accepted) {
      _applyingEngineMove = false;
      await _finishFromBoard();
    }
  }

  void _playMoveSound() {
    if (board.history.isEmpty) return;
    final move = board.history.last.move;
    final SoundEffect effect;
    if (board.isCheckmate) {
      effect = SoundEffect.mate;
    } else if (board.isInCheck) {
      effect = SoundEffect.check;
    } else if ((move.flags & chess.Chess.BITS_CAPTURE) != 0 ||
        (move.flags & chess.Chess.BITS_EP_CAPTURE) != 0) {
      effect = SoundEffect.capture;
    } else {
      effect = SoundEffect.move;
    }
    unawaited(_services.sound.play(effect));
  }

  Future<void> _finishFromBoard() async {
    if (board.isCheckmate) {
      await finish(
        board.playerColor == PlayerColor.black
            ? GameOutcome.win
            : GameOutcome.loss,
      );
      return;
    }
    if (board.isGameOver) {
      await finish(GameOutcome.draw);
    }
  }

  Future<void> abort() async {
    if (_summary != null || _finishing) return;
    await finish(GameOutcome.aborted);
  }

  Future<void> finish(GameOutcome outcome) async {
    if (_finishing || _summary != null) return;
    _finishing = true;
    _phase = GamePhase.finished;
    _task = null;
    _hintMove = null;
    _hintText = null;
    _hintLoading = false;
    _notice = null;
    try {
      await _services.stats.finishSession(sessionId, outcome);
    } catch (error, stackTrace) {
      debugPrint('GameController: не удалось завершить сессию: $error\n$stackTrace');
    }
    _summary = GameSummary(
      outcome: outcome,
      tasksTotal: _tasksTotal,
      tasksSolved: _tasksSolved,
      tasksFirstTry: _tasksFirstTry,
      movesMade: _movesMade,
      weakWordIds: List<String>.unmodifiable(_weakWordOrder),
      lessonId: lesson?.id,
      isLessonGame: isLessonGame,
      isTraining: trainingMode,
      engineUnavailable: _engineUnavailable,
    );
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    board.removeListener(_onBoardChanged);
    unawaited(_engine.dispose());
    super.dispose();
  }
}
