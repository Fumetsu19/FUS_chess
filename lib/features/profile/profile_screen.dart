import 'package:flutter/material.dart';

import '../../core/models/progress.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DashboardData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.services.dashboard();
    if (mounted) setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = _data;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final stats = data.stats;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: AppSpacing.page,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(24),
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary.withAlpha(100)),
                ),
                child: Text(
                  '♞',
                  style: TextStyle(
                    fontSize: 34,
                    height: 1,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Твой профиль', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Уровень ${data.currentLevel.label} · '
                      '${data.completedLessons} уроков пройдено',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('A1 → B1', style: theme.textTheme.labelSmall),
                    const Spacer(),
                    Text(
                      '${(data.progress * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: LinearProgressIndicator(
                    value: data.progress,
                    minHeight: 9,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${data.completedLessons} из ${data.plannedTotal} запланированных уроков',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  icon: Icons.task_alt_rounded,
                  value: '${stats.totalTasks}',
                  label: 'Задач решено',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.my_location_rounded,
                  value: '${(stats.accuracy * 100).round()}%',
                  label: 'Точность',
                  accent: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  value: '${stats.streakDays}',
                  label: 'Дней подряд',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.menu_book_rounded,
                  value: '${stats.lessonsCompleted}',
                  label: 'Уроков',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Сегодня', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _GoalRow(
                  icon: Icons.task_alt_rounded,
                  label: 'Задачи',
                  value: '${data.dailyGoal.tasksToday} / 5',
                  done: data.dailyGoal.tasksToday >= 5,
                ),
                const SizedBox(height: 10),
                _GoalRow(
                  icon: Icons.menu_book_rounded,
                  label: 'Урок',
                  value: '${data.dailyGoal.lessonsToday} / 1',
                  done: data.dailyGoal.lessonsToday >= 1,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: LinearProgressIndicator(
                    value: data.dailyGoal.progress,
                    minHeight: 7,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.dailyGoal.achieved
                      ? 'Цель дня выполнена — отличная работа.'
                      : 'Цель дня: 1 урок или 5 задач.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: data.dailyGoal.achieved ? scheme.secondary : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _PlainStat(
                    label: 'Партий',
                    value: '${stats.gamesPlayed}',
                  ),
                ),
                Expanded(
                  child: _PlainStat(
                    label: 'Побед',
                    value: '${stats.wins}',
                  ),
                ),
                Expanded(
                  child: _PlainStat(
                    label: 'К повторению',
                    value: '${data.dueCount}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Точность = задачи, решённые с первой попытки / все задачи.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 20,
            color: accent ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: accent ? scheme.primary : null,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.done,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: <Widget>[
        Icon(
          done ? Icons.check_circle_rounded : icon,
          size: 18,
          color: done ? scheme.secondary : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: done ? scheme.secondary : null,
          ),
        ),
      ],
    );
  }
}

class _PlainStat extends StatelessWidget {
  const _PlainStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Text(value, style: theme.textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
