import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/b1_test.dart';
import '../../core/models/lesson.dart';
import '../../core/models/progress.dart';
import '../../core/navigation.dart';
import '../../core/services/app_services.dart';
import '../../core/services/b1_test_builder.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../lessons/lessons_screen.dart';

class B1TestScreen extends StatefulWidget {
  const B1TestScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<B1TestScreen> createState() => _B1TestScreenState();
}

class _B1TestScreenState extends State<B1TestScreen> {
  DashboardData? _data;
  List<B1TestQuestion> _questions = const <B1TestQuestion>[];
  final Map<int, bool> _answers = <int, bool>{};
  final TextEditingController _text = TextEditingController();
  final List<int> _selectedWords = <int>[];
  B1TestResult? _result;
  int? _selectedOption;
  int _index = 0;
  int? _sessionId;
  bool _started = false;
  bool _loading = true;
  bool _starting = false;
  bool _closing = false;

  B1TestQuestion get _question => _questions[_index];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final data = await widget.services.dashboard();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final questions = const B1TestBuilder().build(widget.services.content);
      final sessionId = await widget.services.stats.startSession();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _answers.clear();
        _selectedWords.clear();
        _text.clear();
        _selectedOption = null;
        _index = 0;
        _result = null;
        _sessionId = sessionId;
        _started = true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось собрать тест: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  bool get _canSubmit {
    final question = _question;
    if (question.reading != null) return _selectedOption != null;
    switch (question.exercise!.type) {
      case ExerciseType.multipleChoice:
        return _selectedOption != null;
      case ExerciseType.fillBlank:
        return _text.text.trim().isNotEmpty;
      case ExerciseType.buildSentence:
        return _selectedWords.isNotEmpty;
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _result != null) return;
    final question = _question;
    final bool correct;
    if (question.reading != null) {
      correct = question.isCorrectIndex(_selectedOption!);
    } else {
      correct = switch (question.exercise!.type) {
        ExerciseType.multipleChoice =>
          question.isCorrectIndex(_selectedOption!),
        ExerciseType.fillBlank => question.acceptsText(_text.text),
        ExerciseType.buildSentence => question.acceptsBuiltSentence(
            _selectedWords.map((index) => question.exercise!.words[index]).toList(),
          ),
      };
    }
    _answers[_index] = correct;
    final sessionId = _sessionId;
    if (sessionId != null) {
      await widget.services.stats.addTask(sessionId, firstTry: correct);
    }
    if (!mounted) return;
    if (_index >= _questions.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _selectedWords.clear();
      _text.clear();
    });
  }

  Future<void> _finish() async {
    final sessionId = _sessionId;
    if (sessionId != null) {
      await widget.services.stats.finishSession(sessionId, null);
    }
    final correctBySection = <B1Section, int>{};
    final totalBySection = <B1Section, int>{};
    final weakLessonIds = <String>[];
    var correctTotal = 0;
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final ok = _answers[i] ?? false;
      totalBySection.update(question.section, (value) => value + 1, ifAbsent: () => 1);
      if (ok) {
        correctTotal++;
        correctBySection.update(question.section, (value) => value + 1, ifAbsent: () => 1);
      } else if (question.lessonId != null &&
          !weakLessonIds.contains(question.lessonId)) {
        weakLessonIds.add(question.lessonId!);
      }
    }
    if (!mounted) return;
    setState(() {
      _result = B1TestResult(
        total: _questions.length,
        correct: correctTotal,
        correctBySection: correctBySection,
        totalBySection: totalBySection,
        weakLessonIds: weakLessonIds.take(6).toList(growable: false),
      );
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    if (_started && _result == null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Прервать тест?'),
          content: const Text(
            'Ответы уже отправлены, но результат не будет засчитан. '
            'Можно начать тест заново.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Продолжить'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Выйти'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    _closing = true;
    final sessionId = _sessionId;
    if (sessionId != null && _result == null) {
      await widget.services.stats.finishSession(sessionId, null);
    }
    if (mounted) Navigator.of(context).pop();
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
          ),
          title: const Text('Тест B1'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _result != null
                ? _ResultView(
                    result: _result!,
                    lessons: widget.services.content.lessons,
                    onRestart: () => unawaited(_start()),
                    onLessons: () => pushFromRoot(
                      context,
                      LessonsScreen(services: widget.services),
                    ),
                    onHome: () => popToRoot(context),
                  )
                : _started
                    ? _buildQuestion(context)
                    : _buildIntro(context),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    final data = _data;
    final unlocked = data?.b1TestUnlocked ?? false;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: AppSpacing.page,
          children: <Widget>[
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(22),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(100),
                  ),
                ),
                child: Icon(
                  unlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              unlocked ? 'Проверка уровня B1' : 'Тест B1 пока закрыт',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              unlocked
                  ? '30 вопросов по грамматике, лексике, письму и чтению. '
                      'Проходной балл — 70%. Без подсказок и повторов.'
                  : 'Сначала заверши все 80 уроков B1. Так тест проверит '
                      'материал, который ты уже прошёл.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text('B1', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      Text(
                        '${data?.b1Completed ?? 0} / ${data?.b1Total ?? 80} уроков',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: LinearProgressIndicator(
                      value: data?.b1Progress ?? 0,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unlocked
                        ? 'Доступ открыт. Можно проверить себя в формате экзамена.'
                        : 'Откроется после последнего урока B1.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Что проверяет тест', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  for (final section in B1Section.values) ...<Widget>[
                    _Bullet(
                      icon: switch (section) {
                        B1Section.grammar => Icons.rule_rounded,
                        B1Section.vocabulary => Icons.translate_rounded,
                        B1Section.writing => Icons.edit_note_rounded,
                        B1Section.reading => Icons.menu_book_rounded,
                      },
                      text: switch (section) {
                        B1Section.grammar => 'Грамматика в контексте',
                        B1Section.vocabulary => 'Лексика B1',
                        B1Section.writing => 'Сборка связных предложений',
                        B1Section.reading => 'Понимание коротких текстов',
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('B1 — это когда ты можешь:', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  for (final item in B1TestPolicy.canDo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.check_rounded,
                              size: 16, color: theme.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item, style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: unlocked && !_starting ? () => unawaited(_start()) : null,
              icon: _starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(unlocked ? 'Начать тест' : 'Сначала пройди уроки B1'),
            ),
            if (!unlocked) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: data == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Вернуться'),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Это тренировочный тест по дескрипторам B1, а не официальный '
              'экзамен и не сертификат.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final question = _question;
    final progress = (_index + 1) / _questions.length;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    'ВОПРОС ${_index + 1} ИЗ ${_questions.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  LevelBadge(label: question.section.label),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
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
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: <Widget>[
              if (question.reading != null) ...<Widget>[
                Text(
                  question.reading!.title,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SectionCard(
                  child: Text(
                    question.reading!.text,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text(question.prompt, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              if (question.reading != null ||
                  question.exercise?.type == ExerciseType.multipleChoice)
                _Choices(
                  options: question.options,
                  selected: _selectedOption,
                  onSelected: (index) => setState(() => _selectedOption = index),
                )
              else if (question.exercise?.type == ExerciseType.fillBlank)
                TextField(
                  controller: _text,
                  autocorrect: false,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Впиши ответ'),
                )
              else
                _SentenceBuilder(
                  words: question.exercise!.words,
                  selected: _selectedWords,
                  onToggle: (index) {
                    setState(() {
                      if (_selectedWords.contains(index)) {
                        _selectedWords.remove(index);
                      } else {
                        _selectedWords.add(index);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: FilledButton(
              onPressed: _canSubmit ? () => unawaited(_submit()) : null,
              child: Text(_index == _questions.length - 1 ? 'Завершить тест' : 'Ответить'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: <Widget>[
        for (var i = 0; i < options.length; i++) ...<Widget>[
          Material(
            color: selected == i
                ? scheme.primary.withAlpha(24)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => onSelected(i),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == i ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      selected == i
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 19,
                      color: selected == i ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(options[i], style: theme.textTheme.bodyLarge),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i != options.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _SentenceBuilder extends StatelessWidget {
  const _SentenceBuilder({
    required this.words,
    required this.selected,
    required this.onToggle,
  });

  final List<String> words;
  final List<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sentence = selected.map((index) => words[index]).join(' ');
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
          child: sentence.isEmpty
              ? Text('Нажимай на слова ниже', style: theme.textTheme.bodySmall)
              : Text(sentence, style: theme.textTheme.bodyLarge),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (var i = 0; i < words.length; i++)
              FilterChip(
                label: Text(words[i]),
                selected: selected.contains(i),
                onSelected: (_) => onToggle(i),
                showCheckmark: false,
                backgroundColor: scheme.surface,
                selectedColor: scheme.primary.withAlpha(38),
                side: BorderSide(
                  color: selected.contains(i) ? scheme.primary : scheme.outlineVariant,
                ),
                labelStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: selected.contains(i) ? scheme.primary : scheme.onSurface,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.lessons,
    required this.onRestart,
    required this.onLessons,
    required this.onHome,
  });

  final B1TestResult result;
  final List<Lesson> lessons;
  final VoidCallback onRestart;
  final VoidCallback onLessons;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final passed = result.passed;
    final color = passed ? const Color(0xFF59B97E) : scheme.primary;
    return ListView(
      padding: AppSpacing.page,
      children: <Widget>[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                passed ? Icons.workspace_premium_rounded : Icons.school_outlined,
                size: 54,
                color: color,
              ),
              const SizedBox(height: 10),
              Text(
                passed ? 'B1 подтверждён на практике' : 'Пока не хватает баллов',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${result.correct} / ${result.total} · ${result.percent}%',
                style: theme.textTheme.displayMedium?.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(
                'Проходной балл: ${B1TestPolicy.passScore} из ${B1TestPolicy.totalQuestions} (70%)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('По разделам', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final section in B1Section.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 100,
                        child: Text(section.label, style: theme.textTheme.bodyMedium),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: result.sectionTotal(section) == 0
                                ? 0
                                : result.sectionCorrect(section) /
                                    result.sectionTotal(section),
                            minHeight: 7,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${result.sectionCorrect(section)}/${result.sectionTotal(section)}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (result.weakLessonIds.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Стоит повторить', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Эти темы встретились в вопросах с ошибкой.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                for (final id in result.weakLessonIds)
                  if (lessons.where((lesson) => lesson.id == id).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.refresh_rounded,
                              size: 16, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lessons.firstWhere((lesson) => lesson.id == id).title,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('B1 — это когда ты можешь:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              for (final item in B1TestPolicy.canDo)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        passed ? Icons.check_circle_rounded : Icons.circle_outlined,
                        size: 16,
                        color: passed ? scheme.secondary : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Пройти ещё раз'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: onLessons, child: const Text('К урокам')),
        const SizedBox(height: 10),
        TextButton(onPressed: onHome, child: const Text('На главный экран')),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: theme.colorScheme.primary),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
