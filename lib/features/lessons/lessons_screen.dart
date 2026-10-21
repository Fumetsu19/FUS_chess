import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/cefr_level.dart';
import '../../core/models/lesson.dart';
import '../../core/services/app_services.dart';
import '../../core/widgets/common.dart';
import '../b1_test/b1_test_screen.dart';
import 'lesson_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  Set<String> _completed = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final completed = await widget.services.progress.completedLessonIds();
    if (mounted) setState(() => _completed = completed);
  }

  Future<void> _openLesson(Lesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(
          services: widget.services,
          lesson: lesson,
          isReview: _completed.contains(lesson.id),
        ),
      ),
    );
    await _load();
  }

  Future<void> _openB1Test() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => B1TestScreen(services: widget.services),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessons = widget.services.content.lessons;
    final planned = widget.services.content.plannedTotal;
    final b1Total = lessons.where((lesson) => lesson.level == CefrLevel.b1).length;
    final b1Completed = lessons
        .where((lesson) =>
            lesson.level == CefrLevel.b1 && _completed.contains(lesson.id))
        .length;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Уроки'),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            dividerColor: Colors.transparent,
            tabs: const <Widget>[
              Tab(text: 'A1'),
              Tab(text: 'A2'),
              Tab(text: 'B1'),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
              child: SectionCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'A1 → B1',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_completed.length} / $planned уроков',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: LinearProgressIndicator(
                        value: planned == 0
                            ? 0
                            : (_completed.length / planned).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: <Widget>[
                        _LevelCount(
                          level: CefrLevel.a1,
                          completed: _completed,
                          lessons: lessons,
                        ),
                        const SizedBox(width: 12),
                        _LevelCount(
                          level: CefrLevel.a2,
                          completed: _completed,
                          lessons: lessons,
                        ),
                        const SizedBox(width: 12),
                        _LevelCount(
                          level: CefrLevel.b1,
                          completed: _completed,
                          lessons: lessons,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _LevelList(
                    level: CefrLevel.a1,
                    lessons: lessons,
                    completed: _completed,
                    onOpen: _openLesson,
                  ),
                  _LevelList(
                    level: CefrLevel.a2,
                    lessons: lessons,
                    completed: _completed,
                    onOpen: _openLesson,
                  ),
                  _LevelList(
                    level: CefrLevel.b1,
                    lessons: lessons,
                    completed: _completed,
                    b1Completed: b1Completed,
                    b1Total: b1Total,
                    onOpenTest: _openB1Test,
                    onOpen: _openLesson,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCount extends StatelessWidget {
  const _LevelCount({
    required this.level,
    required this.completed,
    required this.lessons,
  });

  final CefrLevel level;
  final Set<String> completed;
  final List<Lesson> lessons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelLessons =
        lessons.where((lesson) => lesson.level == level).toList(growable: false);
    final done =
        levelLessons.where((lesson) => completed.contains(lesson.id)).length;
    return Expanded(
      child: Row(
        children: <Widget>[
          LevelBadge(label: level.label, compact: true),
          const SizedBox(width: 5),
          Text(
            '$done/${levelLessons.length}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList({
    required this.level,
    required this.lessons,
    required this.completed,
    required this.onOpen,
    this.b1Completed = 0,
    this.b1Total = 0,
    this.onOpenTest,
  });

  final CefrLevel level;
  final List<Lesson> lessons;
  final Set<String> completed;
  final ValueChanged<Lesson> onOpen;
  final int b1Completed;
  final int b1Total;
  final VoidCallback? onOpenTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelLessons = lessons
        .where((lesson) => lesson.level == level)
        .toList(growable: false);
    final showTest = level == CefrLevel.b1;
    final extra = showTest ? 2 : 1;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
      itemCount: levelLessons.length + extra,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${level.label} · ${levelLessons.length} уроков',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        if (showTest && index == 1) {
          final unlocked = b1Total > 0 && b1Completed == b1Total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SectionCard(
              onTap: onOpenTest,
              color: theme.colorScheme.primary.withAlpha(14),
              borderColor: theme.colorScheme.primary.withAlpha(70),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      unlocked
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_outline_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Тест B1', style: theme.textTheme.titleMedium),
                        Text(
                          unlocked
                              ? 'Проверка уровня: 30 вопросов, 70% для прохождения'
                              : 'Откроется после 80 уроков B1 · $b1Completed/$b1Total',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          );
        }
        final lesson = levelLessons[index - extra];
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: _LessonTile(
            lesson: lesson,
            completed: completed.contains(lesson.id),
            onTap: () => onOpen(lesson),
          ),
        );
      },
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.completed,
    required this.onTap,
  });

  final Lesson lesson;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: completed
                  ? scheme.secondary.withAlpha(30)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(13),
            ),
            child: completed
                ? Icon(Icons.check_rounded, color: scheme.secondary, size: 21)
                : Text(
                    '${lesson.order}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(lesson.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  lesson.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
