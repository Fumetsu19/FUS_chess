import 'dart:async';
import 'dart:math';

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';

import '../../core/models/game_summary.dart';
import '../../core/models/lesson.dart';
import '../../core/models/word.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../free_play/training_guide.dart';
import '../results/results_screen.dart';
import 'game_controller.dart';
import 'widgets/task_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.services,
    required this.sessionId,
    required this.isLessonGame,
    this.lesson,
    this.trainingMode = false,
    this.initialTasksTotal = 0,
    this.initialTasksFirstTry = 0,
    this.initialTasksSolved = 0,
  });

  final AppServices services;
  final int sessionId;
  final bool isLessonGame;
  final bool trainingMode;
  final Lesson? lesson;
  final int initialTasksTotal;
  final int initialTasksFirstTry;
  final int initialTasksSolved;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  bool _navigatedToResults = false;

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      services: widget.services,
      sessionId: widget.sessionId,
      isLessonGame: widget.isLessonGame,
      trainingMode: widget.trainingMode,
      lesson: widget.lesson,
      initialTasksTotal: widget.initialTasksTotal,
      initialTasksFirstTry: widget.initialTasksFirstTry,
      initialTasksSolved: widget.initialTasksSolved,
    )..addListener(_onControllerChanged);
    unawaited(_controller.initialize());
  }

  void _onControllerChanged() {
    final summary = _controller.summary;
    if (summary == null || _navigatedToResults || !mounted) return;
    _navigatedToResults = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openResults(summary);
    });
  }

  void _openResults(GameSummary summary) {
    final weakWords = summary.weakWordIds
        .map(widget.services.content.wordById)
        .whereType<Word>()
        .toList(growable: false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          services: widget.services,
          summary: summary,
          weakWords: weakWords,
        ),
      ),
    );
  }

  Future<void> _confirmAbort() async {
    if (_controller.summary != null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Прервать партию?'),
        content: const Text(
          'Партия будет отмечена как «Прервано». Решённые задачи и прогресс SRS сохранятся.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _controller.abort();
    }
  }

  Future<void> _showTrainingGuide() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: const <Widget>[TrainingGuideContent()],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmAbort());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => unawaited(_confirmAbort()),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Завершить партию',
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.trainingMode
                    ? 'Обучение'
                    : widget.isLessonGame
                        ? 'Учебная партия'
                        : 'Свободная партия',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                widget.trainingMode
                    ? 'Подсказка на каждом ходу'
                    : widget.lesson?.title ??
                        'Stockfish · ${_controller.difficulty.label}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          actions: <Widget>[
            if (widget.trainingMode)
              IconButton(
                onPressed: () => unawaited(_showTrainingGuide()),
                icon: const Icon(Icons.menu_book_outlined),
                tooltip: 'Фигуры и правила',
              ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: LevelBadge(
                  label: _controller.difficulty.label,
                  compact: true,
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = min(
                  constraints.maxWidth - 24,
                  constraints.maxHeight * 0.52,
                ).clamp(220.0, 520.0);
                return Stack(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _PlayerBar(
                            name: 'Stockfish 19',
                            meta: _controller.difficulty.label,
                            isBot: true,
                            active:
                                _controller.phase == GamePhase.engineThinking,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: boardSize,
                                height: boardSize,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: scheme.outline.withAlpha(110),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: AdvancedChessBoard(
                                  controller: _controller.board,
                                  enableMoves: _controller.canMove,
                                  boardTheme:
                                      AppTheme.boardTheme(theme.brightness),
                                  coordinates: CoordinateLabels.inside,
                                  moveAnimationDuration:
                                      const Duration(milliseconds: 150),
                                  hintArrow: _controller.hintMove == null
                                      ? null
                                      : HintArrow(
                                          startSquare:
                                              _controller.hintMove!.from,
                                          endSquare:
                                              _controller.hintMove!.to,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _PlayerBar(
                            name: 'Ты',
                            meta: 'Белые · ${_controller.movesMade} ход(ов)',
                            isBot: false,
                            active:
                                _controller.phase == GamePhase.awaitingMove,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                          child: _MoveLine(controller: _controller),
                        ),
                        if (_controller.notice != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 3, 16, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Icon(Icons.info_outline_rounded,
                                    size: 14, color: theme.colorScheme.secondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _controller.notice!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_controller.engineUnavailable)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.warning_amber_rounded,
                                    size: 14, color: scheme.error),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Движок недоступен — соперник играет резервным ходом.',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: scheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: _controller.phase == GamePhase.taskActive
                              ? const SizedBox.shrink()
                              : SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 16, 24),
                                  child: TaskPanel(
                                    controller: _controller,
                                    onContinue: _controller.continueToBoard,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (_controller.phase == GamePhase.taskActive)
                      Positioned.fill(
                        child: _TaskOverlay(
                          controller: _controller,
                          onContinue: _controller.continueToBoard,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TaskOverlay extends StatefulWidget {
  const _TaskOverlay({
    required this.controller,
    required this.onContinue,
  });

  final GameController controller;
  final VoidCallback onContinue;

  @override
  State<_TaskOverlay> createState() => _TaskOverlayState();
}

class _TaskOverlayState extends State<_TaskOverlay> {
  final ScrollController _scroll = ScrollController();
  bool _wasCompleted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _TaskOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    final completed = widget.controller.taskCompleted;
    if (completed && !_wasCompleted) {
      _wasCompleted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      });
    } else if (!completed) {
      _wasCompleted = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetHeight =
            (constraints.maxHeight * 0.66).clamp(320.0, 560.0).toDouble();
        return Stack(
          children: <Widget>[
            const ModalBarrier(
              dismissible: false,
              color: Color(0x66000000),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  width: double.infinity,
                  height: sheetHeight,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 8),
                        Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: scheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scroll,
                            padding:
                                const EdgeInsets.fromLTRB(14, 10, 14, 16),
                            child: TaskPanel(
                              controller: widget.controller,
                              onContinue: widget.onContinue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({
    required this.name,
    required this.meta,
    required this.isBot,
    required this.active,
  });

  final String name;
  final String meta;
  final bool isBot;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isBot
                ? scheme.surfaceContainerHighest
                : scheme.primary.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Icon(
            isBot ? Icons.memory_rounded : Icons.person_rounded,
            size: 17,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Text(name, style: theme.textTheme.titleSmall),
        const SizedBox(width: 8),
        Text(meta, style: theme.textTheme.bodySmall),
        const Spacer(),
        if (active)
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _MoveLine extends StatelessWidget {
  const _MoveLine({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pgn = controller.board.pgn;
    final body = pgn
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final text = body.isEmpty ? 'Ходы появятся здесь' : body;
    return SizedBox(
      height: 24,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.format_list_numbered_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
