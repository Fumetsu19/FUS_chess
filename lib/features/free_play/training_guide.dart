import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common.dart';
import '../game/game_screen.dart';

class PieceGuide {
  const PieceGuide({
    required this.symbol,
    required this.nameRu,
    required this.nameEn,
    required this.movement,
  });

  final String symbol;
  final String nameRu;
  final String nameEn;
  final String movement;
}

const pieceGuides = <PieceGuide>[
  PieceGuide(
    symbol: '♙',
    nameRu: 'Пешка',
    nameEn: 'Pawn',
    movement:
        'Идёт на одну клетку вперёд, с начальной позиции — на две. Бьёт по диагонали. На последней линии превращается в ферзя, ладью, слона или коня.',
  ),
  PieceGuide(
    symbol: '♘',
    nameRu: 'Конь',
    nameEn: 'Knight',
    movement:
        'Ходит буквой «Г»: две клетки прямо и одна вбок. Умеет перепрыгивать через другие фигуры.',
  ),
  PieceGuide(
    symbol: '♗',
    nameRu: 'Слон',
    nameEn: 'Bishop',
    movement:
        'Ходит по диагонали на любое расстояние. Остаётся на своём цвете клеток всю партию.',
  ),
  PieceGuide(
    symbol: '♖',
    nameRu: 'Ладья',
    nameEn: 'Rook',
    movement:
        'Ходит по горизонтали и вертикали на любое расстояние. Участвует в рокировке.',
  ),
  PieceGuide(
    symbol: '♕',
    nameRu: 'Ферзь',
    nameEn: 'Queen',
    movement:
        'Самая сильная фигура: ходит как ладья и слон вместе — по прямым и диагоналям.',
  ),
  PieceGuide(
    symbol: '♔',
    nameRu: 'Король',
    nameEn: 'King',
    movement:
        'Ходит на одну клетку в любом направлении. Если королю некуда уйти и его атакуют — это мат.',
  ),
];

class TrainingGuideContent extends StatelessWidget {
  const TrainingGuideContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Фигуры и их ходы', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Нажми «Начать тренировку» — соперник будет мягким, а стрелка '
          'подскажет хороший ход на каждом ходу.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final piece in pieceGuides) ...<Widget>[
          SectionCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(22),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    piece.symbol,
                    style: TextStyle(
                      fontSize: 32,
                      height: 1,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(piece.nameRu, style: theme.textTheme.titleMedium),
                          const SizedBox(width: 6),
                          Text(
                            piece.nameEn,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(piece.movement, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 6),
        Text('Особые правила', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SectionCard(
          child: Column(
            children: <Widget>[
              _Rule(
                icon: Icons.swap_horiz_rounded,
                title: 'Рокировка',
                text:
                    'Король и ладья меняются местами. Король идёт на две клетки, '
                    'ладья перепрыгивает. Только если между ними пусто и король не под шахом.',
              ),
              _Rule(
                icon: Icons.double_arrow_rounded,
                title: 'Взятие на проходе',
                text:
                    'Если пешка соперника прошла две клетки и встала рядом, '
                    'её можно взять по диагонали — как будто она сделала один шаг.',
              ),
              _Rule(
                icon: Icons.upgrade_rounded,
                title: 'Превращение',
                text:
                    'Пешка, дошедшая до последней линии, становится ферзём, '
                    'ладьёй, слоном или конём.',
              ),
              _Rule(
                icon: Icons.flag_rounded,
                title: 'Шах и мат',
                text:
                    'Шах — король под атакой. Мат — королю некуда уйти. '
                    'Цель партии — поставить мат сопернику.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TrainingGuideScreen extends StatefulWidget {
  const TrainingGuideScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<TrainingGuideScreen> createState() => _TrainingGuideScreenState();
}

class _TrainingGuideScreenState extends State<TrainingGuideScreen> {
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
          trainingMode: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обучение')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              padding: AppSpacing.page,
              children: <Widget>[
                Text(
                  'Шахматы с нуля',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Короткая шпаргалка: как называются фигуры, как они ходят '
                  'и какие правила важно не забыть.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 18),
                const TrainingGuideContent(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: FilledButton.icon(
                onPressed: _starting ? null : () => unawaited(_start()),
                icon: _starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: const Text('Начать тренировку'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
