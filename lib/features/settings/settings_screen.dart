import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/engine_difficulty.dart';
import '../../core/models/progress.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/difficulty_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DashboardData? _data;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await widget.services.dashboard();
    if (mounted) setState(() => _data = data);
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить прогресс?'),
        content: const Text(
          'Будут удалены SRS-карточки, завершённые уроки, статистика и серии. '
          'Тема, звук и уровень движка сохранятся. Это действие нельзя отменить.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _resetting = true);
    await widget.services.resetProgress();
    await _load();
    if (!mounted) return;
    setState(() => _resetting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Прогресс сброшен')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = widget.services.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: AppSpacing.page,
            children: <Widget>[
              SectionCard(
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(22),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _data?.currentLevel.label ?? 'A1',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Текущий уровень',
                              style: theme.textTheme.titleMedium),
                          Text(
                            'Путь A1 → B1 · ${_data?.completedLessons ?? 0} из '
                            '${_data?.plannedTotal ?? 40} уроков',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel('ОФОРМЛЕНИЕ'),
              const SizedBox(height: 8),
              SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SwitchListTile(
                  value: settings.isDark,
                  onChanged: (value) {
                    unawaited(
                      settings.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      ),
                    );
                  },
                  title: const Text('Тёмная тема'),
                  subtitle: Text(
                    settings.isDark
                        ? 'Глубокий graphite и тёплые акценты'
                        : 'Светлая бумажная тема',
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: Icon(
                    settings.isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SectionCard(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SwitchListTile(
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    unawaited(settings.setSoundEnabled(value));
                  },
                  title: const Text('Звуки партии'),
                  subtitle: Text(
                    'Ход, взятие, шах и мат',
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: Icon(
                    settings.soundEnabled
                        ? Icons.volume_up_outlined
                        : Icons.volume_off_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel('СЛОЖНОСТЬ STOCKFISH'),
              const SizedBox(height: 4),
              Text(
                'Отдельная ось сложности. Уровень английских задач от неё не зависит.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              DifficultySelector(
                value: settings.difficulty,
                onChanged: (EngineDifficulty value) {
                  unawaited(settings.setDifficulty(value));
                },
              ),
              const SizedBox(height: 22),
              _SectionLabel('ПОВТОРЕНИЕ'),
              const SizedBox(height: 8),
              SectionCard(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.repeat_rounded, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'К повторению сегодня: ${_data?.dueCount ?? 0}',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            'SRS-очередь обновляется после задач и перестрелки.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel('ПРОГРЕСС'),
              const SizedBox(height: 8),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Сброс прогресса',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Удаляет SRS, уроки и статистику. Настройки не затрагивает.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _resetting ? null : () => unawaited(_confirmReset()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error.withAlpha(120)),
                      ),
                      icon: _resetting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline_rounded),
                      label: const Text('Сбросить прогресс'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel('О ПРИЛОЖЕНИИ'),
              const SizedBox(height: 8),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Wordmark(compact: true),
                        const Spacer(),
                        Text('v1.2.0', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'FUS — короткое имя проекта: FU от Fumetsu и S от Strategy. '
                      'Дальше — просто шахматы, английский и практика.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '160 уроков A1–B1, 642 слова и 800 упражнений. Перед ходом '
                      'в партии — английская задача, дома — SRS-повторение и '
                      'перестрелка. Есть разбор фигур, свободная игра и тест B1.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Всё работает офлайн. Уроки, прогресс, статистика и словарь '
                      'хранятся только на устройстве.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Text('Автор: fumetsu', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    SelectableText(
                      'https://github.com/Fumetsu19',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Данные хранятся только на устройстве. Без сети, аккаунтов и бэкенда.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.3,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

