class GameSummary {
  const GameSummary({
    required this.outcome,
    required this.tasksTotal,
    required this.tasksSolved,
    required this.tasksFirstTry,
    required this.movesMade,
    required this.weakWordIds,
    required this.lessonId,
    required this.isLessonGame,
    this.isTraining = false,
    this.engineUnavailable = false,
  });

  final GameOutcome outcome;
  final int tasksTotal;
  final int tasksSolved;
  final int tasksFirstTry;
  final int movesMade;
  final List<String> weakWordIds;
  final String? lessonId;
  final bool isLessonGame;
  final bool isTraining;
  final bool engineUnavailable;

  double get firstTryAccuracy =>
      tasksTotal == 0 ? 0 : tasksFirstTry / tasksTotal;
}

enum GameOutcome {
  win('win', 'Победа'),
  loss('loss', 'Поражение'),
  draw('draw', 'Ничья'),
  aborted('aborted', 'Прервано');

  const GameOutcome(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static GameOutcome? fromDb(String? value) {
    return switch (value) {
      'win' => GameOutcome.win,
      'loss' => GameOutcome.loss,
      'draw' => GameOutcome.draw,
      'aborted' => GameOutcome.aborted,
      _ => null,
    };
  }
}
