enum EngineDifficulty {
  easy(
    label: 'Лёгкий',
    description: 'Совсем для новичка: ошибки соперника и подсказки',
    skillLevel: 0,
    depth: 1,
    moveTimeMs: 40,
    randomMoveChance: 0.45,
  ),
  medium(
    label: 'Средний',
    description: 'Спокойная игра без спешки',
    skillLevel: 0,
    depth: 1,
    moveTimeMs: 80,
  ),
  hard(
    label: 'Высокий',
    description: 'Уверенный клубный уровень',
    skillLevel: 8,
    depth: 10,
    moveTimeMs: 900,
  ),
  expert(
    label: 'Эксперт',
    description: 'Полная сила Stockfish',
    skillLevel: 18,
    depth: 18,
    moveTimeMs: 2500,
  );

  const EngineDifficulty({
    required this.label,
    required this.description,
    required this.skillLevel,
    required this.depth,
    required this.moveTimeMs,
    this.randomMoveChance = 0,
  });

  final String label;
  final String description;
  final int skillLevel;
  final int depth;
  final int moveTimeMs;
  final double randomMoveChance;

  bool get isBeginner => this == EngineDifficulty.easy;

  static EngineDifficulty fromName(String? value) {
    return EngineDifficulty.values.firstWhere(
      (item) => item.name == value,
      orElse: () => EngineDifficulty.medium,
    );
  }
}
