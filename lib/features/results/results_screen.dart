import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/game_summary.dart';
import '../../core/models/word.dart';
import '../../core/navigation.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../game/game_screen.dart';
import '../lessons/lessons_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.services,
    required this.summary,
    required this.weakWords,
  });

  final AppServices services;
  final GameSummary summary;
  final List<Word> weakWords;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _starting = false;

  Future<void> _playAgain() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final sessionId = await widget.services.stats.startSession(
        lessonId: widget.summary.lessonId,
      );
      if (!mounted) return;
      final lesson = widget.summary.lessonId == null
          ? null
          : widget.services.content.lessonById(widget.summary.lessonId!);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(
            services: widget.services,
            sessionId: sessionId,
            isLessonGame: widget.summary.isLessonGame,
            trainingMode: widget.summary.isTraining,
            lesson: lesson,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _goLessons() {
    pushFromRoot(context, LessonsScreen(services: widget.services));
  }

  void _goHome() => popToRoot(context);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.summary;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _goHome,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'На главный',
          ),
          title: const Text('Итоги партии'),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: AppSpacing.page,
            children: <Widget>[
              const SizedBox(height: 8),
              _OutcomeHero(summary: summary),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary.isTraining
                          ? 'Тренировочная партия'
                          : summary.isLessonGame
                              ? 'Учебная партия'
                              : 'Свободная партия',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (summary.tasksTotal > 0)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: StatBlock(
                              value:
                                  '${summary.tasksSolved} / ${summary.tasksTotal}',
                              label: 'Задач решено',
                            ),
                          ),
                          Expanded(
                            child: StatBlock(
                              value:
                                  '${(summary.firstTryAccuracy * 100).round()}%',
                              label:
                                  'С первой попытки · ${summary.tasksFirstTry}',
                              accent: true,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Без учебных задач — чистая игра.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    if (summary.tasksTotal > 0) ...<Widget>[
                      const SizedBox(height: 18),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatBlock(
                            value: '${summary.movesMade}',
                            label: 'Твоих ходов',
                          ),
                        ),
                        Expanded(
                          child: StatBlock(
                            value: summary.outcome.label,
                            label: 'Результат',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (summary.tasksTotal > 0) ...<Widget>[
                Text('Стоит повторить', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  summary.weakWordIds.isEmpty
                      ? 'Слов с последней ошибкой нет.'
                      : 'Последний ответ по этим словам — неверный.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (widget.weakWords.isEmpty)
                  SectionCard(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.check_circle_outline_rounded,
                            color: theme.colorScheme.secondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Отличная работа: все слова последнего хода решены верно.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final word in widget.weakWords) ...<Widget>[
                    _WeakWordTile(word: word),
                    const SizedBox(height: 8),
                  ],
              ],
              if (summary.engineUnavailable) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Stockfish был недоступен, поэтому соперник делал резервные ходы.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _starting ? null : () => unawaited(_playAgain()),
                icon: _starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.replay_rounded),
                label: const Text('Играть ещё раз'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _goLessons,
                child: const Text('К урокам'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _goHome,
                child: const Text('На главный экран'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeHero extends StatelessWidget {
  const _OutcomeHero({required this.summary});

  final GameSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon, message) = switch (summary.outcome) {
      GameOutcome.win => (
          const Color(0xFF59B97E),
          Icons.emoji_events_rounded,
          'Партия за тобой',
        ),
      GameOutcome.loss => (
          theme.colorScheme.error,
          Icons.shield_outlined,
          'Stockfish оказался сильнее',
        ),
      GameOutcome.draw => (
          theme.colorScheme.primary,
          Icons.handshake_outlined,
          'Ничья — достойный результат',
        ),
      GameOutcome.aborted => (
          theme.colorScheme.onSurfaceVariant,
          Icons.pause_circle_outline_rounded,
          'Партия завершена досрочно',
        ),
    };
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            summary.outcome.label,
            style: theme.textTheme.headlineLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakWordTile extends StatelessWidget {
  const _WeakWordTile({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(word.en, style: theme.textTheme.titleMedium),
                Text(
                  '${word.ru} · ${word.transcription}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          LevelBadge(label: word.level.label, compact: true),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
