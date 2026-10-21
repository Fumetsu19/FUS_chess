import 'package:flutter/material.dart';

import '../../core/models/srs_card.dart';
import '../../core/models/word.dart';
import '../../core/services/app_services.dart';
import '../../core/widgets/common.dart';
import '../lessons/lessons_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final TextEditingController _search = TextEditingController();
  List<Word> _words = const <Word>[];
  Map<String, SrsCard> _cards = const <String, SrsCard>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final completed = await widget.services.progress.completedLessonIds();
    final words = widget.services.content.wordsForLessons(completed);
    final cards = await widget.services.srs.allCards();
    if (!mounted) return;
    setState(() {
      _words = words;
      _cards = cards;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _search.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _words
        : _words
            .where(
              (word) =>
                  word.en.toLowerCase().contains(query) ||
                  word.ru.toLowerCase().contains(query),
            )
            .toList(growable: false);
    final learned = _words
        .where((word) => _cards[word.id]?.learned ?? false)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Словарь')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? EmptyState(
                  icon: Icons.translate_rounded,
                  title: 'Словарь пока пуст',
                  message:
                      'Пройди первый урок — слова из него появятся здесь. '
                      'Отметка «изучено» появляется после верного повторения.',
                  action: FilledButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              LessonsScreen(services: widget.services),
                        ),
                      );
                      await _load();
                    },
                    child: const Text('К урокам'),
                  ),
                )
              : Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                      child: Column(
                        children: <Widget>[
                          TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              hintText: 'Поиск по английскому или русскому',
                              prefixIcon:
                                  const Icon(Icons.search_rounded, size: 21),
                              suffixIcon: _search.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: _search.clear,
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Text(
                                '${_words.length} слов из пройденных уроков',
                                style: theme.textTheme.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                'Изучено $learned',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'Ничего не найдено',
                              message: 'Попробуй другое написание или перевод.',
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 28),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final word = filtered[index];
                                return _WordTile(
                                  word: word,
                                  card: _cards[word.id],
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word, required this.card});

  final Word word;
  final SrsCard? card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final learned = card?.learned ?? false;
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: <Widget>[
                    Text(word.en, style: theme.textTheme.titleLarge),
                    Text(
                      word.transcription,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              LevelBadge(label: word.level.label, compact: true),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: learned
                      ? theme.colorScheme.secondary.withAlpha(24)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      learned
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 13,
                      color: learned
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      learned ? 'изучено' : 'учим',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: learned
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(word.ru, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '${word.exampleEn} — ${word.exampleRu}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
