import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/engine_difficulty.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/difficulty_selector.dart';
import '../game/game_screen.dart';
import 'training_guide.dart';

class FreePlayScreen extends StatefulWidget {
  const FreePlayScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends State<FreePlayScreen> {
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    final sessionId = await widget.services.stats.startSession();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          services: widget.services,
          sessionId: sessionId,
          isLessonGame: false,
        ),
      ),
    );
  }

  Future<void> _openTraining() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrainingGuideScreen(services: widget.services),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Свободный режим')),
      body: ListenableBuilder(
        listenable: widget.services.settings,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: AppSpacing.page,
                children: <Widget>[
                  SectionCard(
                    onTap: _openTraining,
                    color: scheme.primary.withAlpha(16),
                    borderColor: scheme.primary.withAlpha(80),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary.withAlpha(28),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: scheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Обучение',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Фигуры, правила и подсказка на каждом ходу. '
                                'Тестовая партия без учебных вопросов.',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Открыть обучение  →',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Игра против Stockfish', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Выбери уровень. На лёгком доступна подсказка по ходу. '
                    'Сила движка не связана с уровнем английского.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  DifficultySelector(
                    value: widget.services.settings.difficulty,
                    onChanged: (EngineDifficulty value) {
                      unawaited(widget.services.settings.setDifficulty(value));
                    },
                  ),
                  const SizedBox(height: 22),
                  SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.info_outline_rounded,
                            size: 20, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ты играешь белыми. Доступны рокировка, взятие на '
                            'проходе и превращение пешки.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _starting ? null : () => unawaited(_start()),
                    icon: _starting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
                    label: const Text('Начать партию'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
