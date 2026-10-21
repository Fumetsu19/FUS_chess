import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/word_task.dart';
import '../../core/navigation.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../lessons/lessons_screen.dart';

class ShootoutScreen extends StatefulWidget {
  const ShootoutScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ShootoutScreen> createState() => _ShootoutScreenState();
}

class _ShootoutScreenState extends State<ShootoutScreen> {
  List<WordTask> _tasks = const <WordTask>[];
  int _index = 0;
  int _score = 0;
  bool _loading = true;
  bool _answered = false;
  bool _finished = false;
  bool _closing = false;
  int? _selectedIndex;
  int? _sessionId;

  WordTask get _task => _tasks[_index];

  @override
  void initState() {
    super.initState();
    unawaited(_startRound());
  }

  Future<void> _startRound() async {
    setState(() {
      _loading = true;
      _finished = false;
      _answered = false;
      _selectedIndex = null;
      _index = 0;
      _score = 0;
      _tasks = const <WordTask>[];
    });
    final tasks = await widget.services.taskPicker.pickShootout(count: 10);
    final sessionId = await widget.services.stats.startSession();
    if (!mounted) return;
    if (tasks.isEmpty) {
      await widget.services.stats.finishSession(sessionId, null);
      setState(() {
        _loading = false;
        _tasks = const <WordTask>[];
        _sessionId = null;
      });
      return;
    }
    setState(() {
      _tasks = tasks;
      _sessionId = sessionId;
      _loading = false;
    });
  }

  Future<void> _answer(int index) async {
    if (_answered || _loading) return;
    final task = _task;
    final correct = task.isCorrectIndex(index);
    setState(() {
      _answered = true;
      _selectedIndex = index;
      if (correct) _score++;
    });
    await widget.services.srs.recordAttempt(
      task.word.id,
      correct: correct,
      soft: true,
    );
    if (!correct) {
      await widget.services.adaptive.recordWrong(task.word.id);
    }
    final sessionId = _sessionId;
    if (sessionId != null) {
      await widget.services.stats.addTask(sessionId, firstTry: correct);
    }
  }

  Future<void> _next() async {
    if (!_answered) return;
    if (_index < _tasks.length - 1) {
      setState(() {
        _index++;
        _answered = false;
        _selectedIndex = null;
      });
      return;
    }
    final sessionId = _sessionId;
    if (sessionId != null) {
      await widget.services.stats.finishSession(sessionId, null);
    }
    if (mounted) setState(() => _finished = true);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    final sessionId = _sessionId;
    if (sessionId != null) {
      await widget.services.stats.finishSession(sessionId, null);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _goLessons() {
    pushFromRoot(context, LessonsScreen(services: widget.services));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_close());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => unawaited(_close()),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Закрыть',
          ),
          title: const Text('Перестрелка'),
          actions: <Widget>[
            if (!_loading && !_finished && _tasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    '$_score / ${_tasks.length}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tasks.isEmpty
                ? EmptyState(
                    icon: Icons.bolt_rounded,
                    title: 'Пока нечего повторять',
                    message:
                        'Перестрелка берёт слова из SRS-очереди и изученные '
                        'слова. Пройди урок и ответь на задачи перед ходами.',
                    action: FilledButton(
                      onPressed: _goLessons,
                      child: const Text('К урокам'),
                    ),
                  )
                : _finished
                    ? _RoundSummary(
                        score: _score,
                        total: _tasks.length,
                        onRestart: () => unawaited(_startRound()),
                        onHome: () => popToRoot(context),
                      )
                    : _buildQuiz(context),
      ),
    );
  }

  Widget _buildQuiz(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final task = _task;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: AppSpacing.page,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  'ВОПРОС ${_index + 1} ИЗ ${_tasks.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                const LevelBadge(label: 'SRS', compact: true),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_index + 1) / _tasks.length,
                minHeight: 5,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 24),
            SectionCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: <Widget>[
                  Text(
                    'Выбери перевод',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    task.word.en,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${task.word.transcription} · ${task.word.partOfSpeech}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < task.options.length; i++) ...<Widget>[
                    _QuizOption(
                      label: task.options[i],
                      index: i,
                      answered: _answered,
                      selected: _selectedIndex == i,
                      correctIndex: task.correctIndex,
                      onTap: () => unawaited(_answer(i)),
                    ),
                    if (i != task.options.length - 1)
                      const SizedBox(height: 9),
                  ],
                  if (_answered) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_selectedIndex == task.correctIndex
                                ? const Color(0xFF59B97E)
                                : scheme.error)
                            .withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_selectedIndex == task.correctIndex
                                  ? const Color(0xFF59B97E)
                                  : scheme.error)
                              .withAlpha(80),
                        ),
                      ),
                      child: Text(
                        _selectedIndex == task.correctIndex
                            ? 'Верно!'
                            : 'Правильный ответ: ${task.correctAnswer}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _selectedIndex == task.correctIndex
                              ? const Color(0xFF59B97E)
                              : scheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => unawaited(_next()),
                      child: Text(
                        _index == _tasks.length - 1 ? 'Итоги' : 'Дальше',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.label,
    required this.index,
    required this.answered,
    required this.selected,
    required this.correctIndex,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool answered;
  final bool selected;
  final int correctIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final correct = answered && index == correctIndex;
    final wrong = answered && selected && index != correctIndex;
    final background = correct
        ? const Color(0xFF2E6B48).withAlpha(36)
        : wrong
            ? scheme.error.withAlpha(24)
            : scheme.surfaceContainerHighest;
    final border = correct
        ? const Color(0xFF59B97E)
        : wrong
            ? scheme.error
            : scheme.outlineVariant;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: answered ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(label, style: theme.textTheme.bodyLarge),
              ),
              if (correct)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF59B97E), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundSummary extends StatelessWidget {
  const _RoundSummary({
    required this.score,
    required this.total,
    required this.onRestart,
    required this.onHome,
  });

  final int score;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accuracy = total == 0 ? 0 : (score / total * 100).round();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: AppSpacing.page,
          children: <Widget>[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scheme.primary.withAlpha(70)),
              ),
              child: Column(
                children: <Widget>[
                  Icon(Icons.bolt_rounded, size: 44, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('Раунд завершён', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    '$score из $total',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    'Точность $accuracy%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              child: Text(
                'Интервалы повторения не менялись — перестрелка мягко '
                'влияет только на ease и счётчик повторений.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Ещё раунд'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onHome,
              child: const Text('На главный экран'),
            ),
          ],
        ),
      ),
    );
  }
}
