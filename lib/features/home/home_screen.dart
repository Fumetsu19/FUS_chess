import 'package:flutter/material.dart';

import '../../core/models/progress.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../b1_test/b1_test_screen.dart';
import '../free_play/free_play_screen.dart';
import '../lessons/lesson_screen.dart';
import '../lessons/lessons_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../shootout/shootout_screen.dart';
import '../vocabulary/vocabulary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.services.dashboard();
  }

  void _reload() {
    setState(() {
      _future = widget.services.dashboard();
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) _reload();
  }

  Future<void> _play(DashboardData data) async {
    final lesson = data.nextLesson;
    if (lesson == null) {
      await _open(FreePlayScreen(services: widget.services));
      return;
    }
    await _open(
      LessonScreen(
        services: widget.services,
        lesson: lesson,
        isReview: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Wordmark(compact: true),
        actions: <Widget>[
          IconButton(
            onPressed: () => _open(ProfileScreen(services: widget.services)),
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Профиль',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Не удалось загрузить прогресс',
              message: '${snapshot.error ?? 'Неизвестная ошибка'}',
              action: FilledButton(
                onPressed: _reload,
                child: const Text('Повторить'),
              ),
            );
          }
          final data = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: AppSpacing.page,
                children: <Widget>[
                  Text(
                    'Твой следующий ход',
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Один ход — одно новое слово. Играй и учись без спешки.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ProgressOverview(data: data),
                  const SizedBox(height: 14),
                  _PlayCard(
                    data: data,
                    onTap: () => _play(data),
                  ),
                  const SizedBox(height: 22),
                  _MenuTile(
                    icon: Icons.menu_book_rounded,
                    title: 'Уроки',
                    subtitle:
                        '${data.actualTotal} уроков A1–B1 · пройдено ${data.completedLessons}',
                    onTap: () => _open(
                      LessonsScreen(services: widget.services),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _MenuTile(
                    icon: data.b1TestUnlocked
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_outline_rounded,
                    title: 'Тест B1',
                    subtitle: data.b1TestUnlocked
                        ? 'Проверка уровня: 30 вопросов, проходной балл 70%'
                        : 'Откроется после 80 уроков B1 · ${data.b1Completed}/${data.b1Total}',
                    onTap: () => _open(
                      B1TestScreen(services: widget.services),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _MenuTile(
                    icon: Icons.translate_rounded,
                    title: 'Словарь',
                    subtitle: 'Слова из пройденных уроков · поиск',
                    onTap: () => _open(
                      VocabularyScreen(services: widget.services),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _MenuTile(
                    icon: Icons.bolt_rounded,
                    title: 'Перестрелка',
                    subtitle: 'Быстрая викторина: слово → перевод',
                    onTap: () => _open(
                      ShootoutScreen(services: widget.services),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _MenuTile(
                    icon: Icons.sports_esports_outlined,
                    title: 'Свободный режим',
                    subtitle: 'Чистая партия против Stockfish',
                    onTap: () => _open(
                      FreePlayScreen(services: widget.services),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _MenuTile(
                    icon: Icons.tune_rounded,
                    title: 'Настройки',
                    subtitle: 'Тема, звук, уровень движка',
                    onTap: () => _open(
                      SettingsScreen(services: widget.services),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'fumetsu · github.com/Fumetsu19',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.data});

  final DashboardData data;

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
              Text(
                'A1 → B1',
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              LevelBadge(label: data.currentLevel.label),
              const SizedBox(width: 8),
              Text(
                '${data.completedLessons} / ${data.plannedTotal}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 9,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Text('A1', style: theme.textTheme.labelSmall),
              const Spacer(),
              Text('A2', style: theme.textTheme.labelSmall),
              const Spacer(),
              Text('B1', style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniMetric(
                  icon: Icons.repeat_rounded,
                  title: 'К повторению',
                  value: '${data.dueCount}',
                  accent: data.dueCount > 0,
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: scheme.outlineVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MiniMetric(
                  icon: data.dailyGoal.achieved
                      ? Icons.check_circle_rounded
                      : Icons.today_rounded,
                  title: 'Цель дня',
                  value: data.dailyGoal.achieved
                      ? 'выполнена'
                      : '${data.dailyGoal.tasksToday}/5 задач',
                  accent: data.dailyGoal.achieved,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Icon(Icons.local_fire_department_rounded,
                  size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Серия: ${data.stats.streakDays} дн.',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                'Точность: ${(data.stats.accuracy * 100).round()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        accent ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Row(
      children: <Widget>[
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent ? theme.colorScheme.primary : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayCard extends StatelessWidget {
  const _PlayCard({required this.data, required this.onTap});

  final DashboardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final next = data.nextLesson;
    final subtitle = next == null
        ? 'Все 160 уроков пройдены. Сыграй свободную партию.'
        : 'Продолжить: урок ${next.order} · ${next.title}';
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -18,
              top: -26,
              child: Text(
                '♞',
                style: TextStyle(
                  fontSize: 120,
                  height: 1,
                  color: scheme.onPrimary.withAlpha(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'ТВОЙ ХОД',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onPrimary.withAlpha(180),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Играть',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimary.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withAlpha(28),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: scheme.onPrimary,
                      size: 27,
                    ),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 21, color: scheme.onSurface),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

