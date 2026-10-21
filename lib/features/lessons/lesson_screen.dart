import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/game_summary.dart';
import '../../core/models/lesson.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../game/game_screen.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.services,
    required this.lesson,
    required this.isReview,
  });

  final AppServices services;
  final Lesson lesson;
  final bool isReview;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<int> _selectedWords = <int>[];

  late List<Exercise> _exercises;
  int? _sessionId;
  Future<int>? _sessionFuture;
  bool _theory = true;
  bool _adaptiveMode = false;
  bool _navigatedToGame = false;
  bool _startingGame = false;

  int _index = 0;
  int _attempts = 0;
  bool _exerciseCompleted = false;
  bool _exerciseSolved = false;
  bool _firstTry = false;
  bool _hintVisible = false;
  int? _wrongOption;

  int _tasksTotal = 0;
  int _tasksFirstTry = 0;
  int _tasksSolved = 0;

  Exercise get _exercise => _exercises[_index];

  @override
  void initState() {
    super.initState();
    _exercises = List<Exercise>.of(widget.lesson.exercises);
    unawaited(_prepare());
  }

  Future<int> _startSession() {
    return _sessionFuture ??= widget.services.stats.startSession(
      lessonId: widget.lesson.id,
    );
  }

  Future<void> _prepare() async {
    final prefersFill = await widget.services.adaptive
        .prefersFillBlank(widget.lesson.id);
    final sessionId = await _startSession();
    if (!mounted) return;
    setState(() {
      if (_theory) {
        _adaptiveMode = prefersFill;
        if (prefersFill) {
          final production = widget.lesson.exercises
              .where((exercise) => exercise.type != ExerciseType.multipleChoice)
              .toList(growable: false);
          if (production.isNotEmpty) _exercises = production;
        }
      }
      _sessionId = sessionId;
    });
  }

  Future<void> _ensureSession() async {
    if (_sessionId != null) return;
    final id = await _startSession();
    if (mounted) setState(() => _sessionId = id);
  }

  Future<void> _confirmExit() async {
    if (_navigatedToGame) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из урока?'),
        content: const Text(
          'Незавершённый урок не будет отмечен как пройденный. '
          'Уже решённые задачи сохранятся в статистике.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (result != true) return;
    _navigatedToGame = true;
    var sessionId = _sessionId;
    if (sessionId == null && _sessionFuture != null) {
      try {
        sessionId = await _sessionFuture;
      } catch (error) {
        debugPrint('LessonScreen: сессия не создана: $error');
      }
    }
    if (sessionId != null) {
      await widget.services.stats.finishSession(sessionId, GameOutcome.aborted);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _beginExercises() {
    setState(() {
      _theory = false;
      _resetExerciseState();
    });
  }

  void _resetExerciseState() {
    _attempts = 0;
    _exerciseCompleted = false;
    _exerciseSolved = false;
    _firstTry = false;
    _hintVisible = false;
    _wrongOption = null;
    _textController.clear();
    _selectedWords.clear();
  }

  Future<void> _completeExercise({
    required bool correct,
    required bool firstTry,
  }) async {
    if (_exerciseCompleted) return;
    _exerciseCompleted = true;
    _exerciseSolved = correct;
    _firstTry = firstTry;
    _tasksTotal++;
    if (correct) {
      _tasksSolved++;
    }
    if (firstTry) {
      _tasksFirstTry++;
    }
    setState(() {});
    await _ensureSession();
    final sessionId = _sessionId;
    if (sessionId != null) {
      await widget.services.stats.addTask(sessionId, firstTry: firstTry);
    }
    if (_exercise.type == ExerciseType.multipleChoice) {
      await widget.services.adaptive.recordMcResult(
        widget.lesson.id,
        firstTryCorrect: correct && firstTry,
      );
    }
  }

  void _checkMultipleChoice(int index) {
    if (_exerciseCompleted) return;
    final correct = _exercise.isCorrectIndex(index);
    if (correct) {
      unawaited(_completeExercise(correct: true, firstTry: _attempts == 0));
      return;
    }
    _registerWrong(index: index);
  }

  void _registerWrong({int? index}) {
    if (_exerciseCompleted) return;
    _attempts++;
    _wrongOption = index;
    if (_attempts >= 3) {
      unawaited(_completeExercise(correct: false, firstTry: false));
    } else {
      setState(() {});
    }
  }

  void _checkTextAnswer() {
    if (_exerciseCompleted) return;
    final value = _textController.text;
    if (value.trim().isEmpty) return;
    if (_exercise.acceptsText(value)) {
      unawaited(_completeExercise(correct: true, firstTry: _attempts == 0));
    } else {
      _registerWrong();
    }
  }

  void _checkBuiltSentence() {
    if (_exerciseCompleted) return;
    if (_selectedWords.isEmpty) return;
    final selected =
        _selectedWords.map((index) => _exercise.words[index]).toList();
    if (_exercise.acceptsBuiltSentence(selected)) {
      unawaited(_completeExercise(correct: true, firstTry: _attempts == 0));
    } else {
      _registerWrong();
    }
  }

  Future<void> _nextExercise() async {
    if (!_exerciseCompleted) return;
    if (_index < _exercises.length - 1) {
      setState(() {
        _index++;
        _resetExerciseState();
      });
      return;
    }
    await _finishLesson();
  }

  Future<void> _finishLesson() async {
    if (_startingGame) return;
    setState(() => _startingGame = true);
    await _ensureSession();
    await widget.services.progress.saveLessonResult(
      lessonId: widget.lesson.id,
      exercisesOk: _tasksSolved,
      exercisesAll: _exercises.length,
    );
    final sessionId = _sessionId;
    if (!mounted || sessionId == null) {
      setState(() => _startingGame = false);
      return;
    }
    _navigatedToGame = true;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          services: widget.services,
          sessionId: sessionId,
          isLessonGame: true,
          lesson: widget.lesson,
          initialTasksTotal: _tasksTotal,
          initialTasksFirstTry: _tasksFirstTry,
          initialTasksSolved: _tasksSolved,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => unawaited(_confirmExit()),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Закрыть урок',
          ),
          title: Text(_theory ? 'Урок ${widget.lesson.order}' : 'Практика'),
          actions: <Widget>[
            if (widget.isReview)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(child: LevelBadge(label: 'ПОВТОР')),
              ),
          ],
        ),
        body: _theory ? _buildTheory(context) : _buildPractice(context),
      ),
    );
  }

  Widget _buildTheory(BuildContext context) {
    final theme = Theme.of(context);
    final lesson = widget.lesson;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: AppSpacing.page,
            children: <Widget>[
              Row(
                children: <Widget>[
                  LevelBadge(label: lesson.level.label),
                  const SizedBox(width: 8),
                  Text(
                    'ТЕОРИЯ',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(lesson.title, style: theme.textTheme.headlineLarge),
              const SizedBox(height: 6),
              Text(
                lesson.summary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < lesson.theory.length; i++) ...<Widget>[
                _TheoryBlockView(block: lesson.theory[i]),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              SectionCard(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.menu_book_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'После статьи — ${_exercises.length} упражнений и партия '
                        'с задачами перед каждым ходом.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: _beginExercises,
              child: Text('К упражнениям · ${_exercises.length}'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPractice(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_index + 1) / _exercises.length;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'УПРАЖНЕНИЕ ${_index + 1} ИЗ ${_exercises.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (_adaptiveMode)
                    const LevelBadge(label: 'АДАПТАЦИЯ', compact: true),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: <Widget>[
              if (_adaptiveMode) ...<Widget>[
                Text(
                  'MC-серия пройдена — тренируем письменные ответы.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _ExerciseCard(
                exercise: _exercise,
                textController: _textController,
                selectedWords: _selectedWords,
                completed: _exerciseCompleted,
                solved: _exerciseSolved,
                attempts: _attempts,
                hintVisible: _hintVisible,
                wrongOption: _wrongOption,
                onShowHint: () => setState(() => _hintVisible = true),
                onChoice: _checkMultipleChoice,
                onCheckText: _checkTextAnswer,
                onToggleWord: (index) {
                  if (_exerciseCompleted) return;
                  setState(() {
                    if (_selectedWords.contains(index)) {
                      _selectedWords.remove(index);
                    } else {
                      _selectedWords.add(index);
                    }
                  });
                },
                onCheckBuilt: _checkBuiltSentence,
              ),
              if (_exerciseCompleted) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (_exerciseSolved
                            ? const Color(0xFF59B97E)
                            : theme.colorScheme.error)
                        .withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_exerciseSolved
                              ? const Color(0xFF59B97E)
                              : theme.colorScheme.error)
                          .withAlpha(80),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _exerciseSolved
                            ? (_firstTry
                                ? 'Верно с первой попытки'
                                : 'Верно')
                            : 'Правильный ответ',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _exerciseSolved
                              ? const Color(0xFF59B97E)
                              : theme.colorScheme.error,
                        ),
                      ),
                      if (!_exerciseSolved || _exercise.type != ExerciseType.multipleChoice) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          _exercise.type == ExerciseType.multipleChoice
                              ? _exercise.options[_exercise.correctIndex]
                              : _exercise.answer,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (_exerciseCompleted)
                FilledButton(
                  onPressed: _startingGame
                      ? null
                      : () => unawaited(_nextExercise()),
                  child: _startingGame
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _index == _exercises.length - 1
                              ? 'Начать партию'
                              : 'Дальше',
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TheoryBlockView extends StatelessWidget {
  const _TheoryBlockView({required this.block});

  final TheoryBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    switch (block.type) {
      case TheoryBlockType.text:
        return Text(
          block.content,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        );
      case TheoryBlockType.example:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: scheme.primary, width: 3),
            ),
          ),
          child: Text(
            block.content,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        );
      case TheoryBlockType.note:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.secondary.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.secondary.withAlpha(60)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.lightbulb_outline_rounded,
                  size: 20, color: scheme.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(block.content, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        );
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.textController,
    required this.selectedWords,
    required this.completed,
    required this.solved,
    required this.attempts,
    required this.hintVisible,
    required this.wrongOption,
    required this.onShowHint,
    required this.onChoice,
    required this.onCheckText,
    required this.onToggleWord,
    required this.onCheckBuilt,
  });

  final Exercise exercise;
  final TextEditingController textController;
  final List<int> selectedWords;
  final bool completed;
  final bool solved;
  final int attempts;
  final bool hintVisible;
  final int? wrongOption;
  final VoidCallback onShowHint;
  final ValueChanged<int> onChoice;
  final VoidCallback onCheckText;
  final ValueChanged<int> onToggleWord;
  final VoidCallback onCheckBuilt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              LevelBadge(label: exercise.type.label, compact: true),
              const Spacer(),
              _AttemptsBadge(attempts: attempts, completed: completed),
              const SizedBox(width: 4),
              IconButton(
                onPressed: hintVisible ? null : onShowHint,
                tooltip: 'Подсказка',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.question_mark_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.primary,
                  disabledForegroundColor: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(exercise.prompt, style: theme.textTheme.headlineMedium),
          if (hintVisible) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondary.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Подсказка: ${exercise.hint}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          const SizedBox(height: 16),
          switch (exercise.type) {
            ExerciseType.multipleChoice => _buildChoices(context),
            ExerciseType.fillBlank => _buildFill(context),
            ExerciseType.buildSentence => _buildSentence(context),
          },
        ],
      ),
    );
  }

  Widget _buildChoices(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: <Widget>[
        for (var i = 0; i < exercise.options.length; i++) ...<Widget>[
          Builder(
            builder: (context) {
              final isCorrect = i == exercise.correctIndex;
              final isWrong = wrongOption == i;
              var background = scheme.surfaceContainerHighest;
              var border = scheme.outlineVariant;
              var foreground = scheme.onSurface;
              if (completed && isCorrect) {
                background = const Color(0xFF2E6B48).withAlpha(36);
                border = const Color(0xFF59B97E);
                foreground = const Color(0xFF59B97E);
              } else if (!completed && isWrong) {
                background = scheme.error.withAlpha(24);
                border = scheme.error;
                foreground = scheme.error;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: background,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: completed ? null : () => onChoice(i),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        children: <Widget>[
                          Text(
                            String.fromCharCode(65 + i),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              exercise.options[i],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: foreground,
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
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFill(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: textController,
          enabled: !completed,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          onSubmitted: (_) => onCheckText(),
          decoration: const InputDecoration(
            hintText: 'Впиши слово или фразу',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: completed ? null : onCheckText,
          child: const Text('Проверить'),
        ),
      ],
    );
  }

  Widget _buildSentence(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedText =
        selectedWords.map((index) => exercise.words[index]).join(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: selectedText.isEmpty
              ? Text(
                  'Нажимай на слова ниже',
                  style: theme.textTheme.bodySmall,
                )
              : Text(selectedText, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (var i = 0; i < exercise.words.length; i++)
              FilterChip(
                label: Text(exercise.words[i]),
                selected: selectedWords.contains(i),
                onSelected: completed ? null : (_) => onToggleWord(i),
                showCheckmark: false,
                backgroundColor: scheme.surface,
                selectedColor: scheme.primary.withAlpha(38),
                side: BorderSide(
                  color: selectedWords.contains(i)
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: selectedWords.contains(i)
                      ? scheme.primary
                      : scheme.onSurface,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: completed ? null : onCheckBuilt,
          child: const Text('Проверить'),
        ),
      ],
    );
  }
}

class _AttemptsBadge extends StatelessWidget {
  const _AttemptsBadge({required this.attempts, required this.completed});

  final int attempts;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (completed) {
      return Text(
        'ГОТОВО',
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.secondary,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    return Text(
      attempts == 0 ? '3 ПОПЫТКИ' : 'ОСТАЛОСЬ ${3 - attempts}',
      style: theme.textTheme.labelSmall?.copyWith(
        color: attempts > 0 ? scheme.error : scheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
