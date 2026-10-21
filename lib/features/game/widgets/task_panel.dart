import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/word_task.dart';
import '../../../core/widgets/common.dart';
import '../game_controller.dart';

class TaskPanel extends StatelessWidget {
  const TaskPanel({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  final GameController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final phase = controller.phase;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (phase) {
        GamePhase.loadingTask => const _LoadingPanel(key: ValueKey('loading')),
        GamePhase.taskActive => _TaskCard(
            key: const ValueKey('task'),
            task: controller.task,
            controller: controller,
            onContinue: onContinue,
          ),
        GamePhase.awaitingMove => _TurnPanel(
            key: const ValueKey('turn'),
            title: 'Твой ход',
            message: controller.isTraining
                ? 'Смотри подсказку и пробуй. Ошибаться в обучении можно.'
                : controller.isLessonGameMode
                    ? 'Задача решена. Сделай ход белыми на доске.'
                    : 'Сделай ход белыми на доске.',
            controller: controller,
          ),
        GamePhase.engineThinking => const _ThinkingPanel(
            key: ValueKey('thinking'),
          ),
        GamePhase.finished => const _TurnPanel(
            key: ValueKey('finished'),
            title: 'Партия завершена',
            message: 'Считаем результат…',
          ),
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.controller,
    required this.onContinue,
  });

  final WordTask? task;
  final GameController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final task = this.task;
    if (task == null) {
      return const _LoadingPanel();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'ПЕРЕД ХОДОМ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              _AttemptDots(attempts: controller.attempts),
              const SizedBox(width: 4),
              IconButton(
                onPressed:
                    controller.hintVisible ? null : controller.showHint,
                tooltip: 'Подсказка',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.primary,
                  disabledBackgroundColor: scheme.surfaceContainerHighest,
                  disabledForegroundColor: scheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.question_mark_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            task.word.en,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: 34,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${task.word.transcription}  ·  ${task.word.partOfSpeech}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Выбери правильный перевод',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (controller.hintVisible) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondary.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.secondary.withAlpha(50)),
              ),
              child: Text(
                'Подсказка: ${task.hint}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < task.options.length; i++) ...<Widget>[
            _OptionButton(
              label: task.options[i],
              letter: String.fromCharCode(65 + i),
              index: i,
              task: task,
              controller: controller,
            ),
            if (i != task.options.length - 1) const SizedBox(height: 8),
          ],
          if (controller.taskCompleted) ...<Widget>[
            const SizedBox(height: 14),
            _ResultBanner(
              solved: controller.taskSolved,
              correctAnswer: task.correctAnswer,
              firstTry: controller.currentTaskFirstTry,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onContinue,
              child: Text(
                controller.taskSolved ? 'К доске' : 'Продолжить',
              ),
            ),
          ] else if (controller.attempts > 0) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Пока неверно. Осталось попыток: ${controller.attemptsLeft}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.letter,
    required this.index,
    required this.task,
    required this.controller,
  });

  final String label;
  final String letter;
  final int index;
  final WordTask task;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = controller.taskCompleted;
    final isCorrect = index == task.correctIndex;
    final isWrong = controller.wrongOptionIndex == index;

    Color background = scheme.surfaceContainerHighest;
    Color border = scheme.outlineVariant;
    Color foreground = scheme.onSurface;
    if (completed && isCorrect) {
      background = const Color(0xFF2E6B48).withAlpha(38);
      border = const Color(0xFF59B97E);
      foreground = const Color(0xFF59B97E);
    } else if (isWrong) {
      background = scheme.error.withAlpha(28);
      border = scheme.error;
      foreground = scheme.error;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: controller.canAnswerTask
            ? () => unawaited(controller.answerWord(index))
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: foreground.withAlpha(16),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  letter,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: foreground,
                    fontSize: 15,
                  ),
                ),
              ),
              if (completed && isCorrect)
                const Icon(Icons.check_circle_rounded,
                    size: 19, color: Color(0xFF59B97E)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttemptDots extends StatelessWidget {
  const _AttemptDots({required this.attempts});

  final int attempts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (index) {
        final used = index < attempts;
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: used ? scheme.error : scheme.outline,
          ),
        );
      }),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.solved,
    required this.correctAnswer,
    required this.firstTry,
  });

  final bool solved;
  final String correctAnswer;
  final bool firstTry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = solved ? const Color(0xFF59B97E) : theme.colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                solved ? Icons.check_circle_rounded : Icons.info_rounded,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                solved ? (firstTry ? 'Верно с первой попытки' : 'Верно') : 'Правильный ответ',
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          if (!solved) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              correctAnswer,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ThinkingPanel extends StatelessWidget {
  const _ThinkingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Stockfish думает', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Следующий ход соперника',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnPanel extends StatelessWidget {
  const _TurnPanel({
    super.key,
    required this.title,
    required this.message,
    this.controller,
  });

  final String title;
  final String message;
  final GameController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final game = controller;
    final showHint = game != null && game.hintsAvailable;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(22),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.touch_app_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(message, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (game != null &&
              (showHint || game.hintLoading || game.hintText != null)) ...<Widget>[
            const SizedBox(height: 12),
            if (game.hintLoading)
              Row(
                children: <Widget>[
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 9),
                  Text('Ищу хороший ход…', style: theme.textTheme.bodySmall),
                ],
              )
            else if (game.hintText != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: scheme.secondary.withAlpha(16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.secondary.withAlpha(55)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 17, color: scheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        game.hintText!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (showHint && !game.hintLoading) ...<Widget>[
              const SizedBox(height: 7),
              TextButton.icon(
                onPressed: () => unawaited(game.requestHint()),
                icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: Text(
                  game.hintText == null ? 'Подсказка' : 'Другая подсказка',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
