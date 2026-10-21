import 'cefr_level.dart';
import 'lesson.dart';
import 'srs_card.dart';

class LessonProgress {
  const LessonProgress({
    required this.lessonId,
    required this.completedAt,
    required this.exercisesOk,
    required this.exercisesAll,
  });

  final String lessonId;
  final DateTime? completedAt;
  final int exercisesOk;
  final int exercisesAll;

  bool get isCompleted => completedAt != null;

  factory LessonProgress.fromMap(Map<String, Object?> map) {
    final completed = map['completed_at'] as String?;
    return LessonProgress(
      lessonId: map['lesson_id']! as String,
      completedAt: completed == null ? null : DateTime.parse(completed).toLocal(),
      exercisesOk: (map['exercises_ok']! as num).toInt(),
      exercisesAll: (map['exercises_all']! as num).toInt(),
    );
  }
}

class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.playedAt,
    required this.lessonId,
    required this.tasksTotal,
    required this.tasksFirstTry,
    required this.movesMade,
    required this.gameResult,
  });

  final int id;
  final DateTime playedAt;
  final String? lessonId;
  final int tasksTotal;
  final int tasksFirstTry;
  final int movesMade;
  final String? gameResult;

  factory SessionRecord.fromMap(Map<String, Object?> map) {
    return SessionRecord(
      id: (map['id']! as num).toInt(),
      playedAt: DateTime.parse(map['played_at']! as String).toLocal(),
      lessonId: map['lesson_id'] as String?,
      tasksTotal: (map['tasks_total'] as num?)?.toInt() ?? 0,
      tasksFirstTry: (map['tasks_first_try'] as num?)?.toInt() ?? 0,
      movesMade: (map['moves_made'] as num?)?.toInt() ?? 0,
      gameResult: map['game_result'] as String?,
    );
  }
}

class ProfileStats {
  const ProfileStats({
    required this.totalTasks,
    required this.tasksFirstTry,
    required this.gamesPlayed,
    required this.wins,
    required this.lessonsCompleted,
    required this.streakDays,
  });

  final int totalTasks;
  final int tasksFirstTry;
  final int gamesPlayed;
  final int wins;
  final int lessonsCompleted;
  final int streakDays;

  double get accuracy => totalTasks == 0 ? 0 : tasksFirstTry / totalTasks;

  static const empty = ProfileStats(
    totalTasks: 0,
    tasksFirstTry: 0,
    gamesPlayed: 0,
    wins: 0,
    lessonsCompleted: 0,
    streakDays: 0,
  );
}

class DailyGoal {
  const DailyGoal({
    required this.tasksToday,
    required this.lessonsToday,
    this.targetTasks = 5,
  });

  final int tasksToday;
  final int lessonsToday;
  final int targetTasks;

  bool get achieved => lessonsToday >= 1 || tasksToday >= targetTasks;

  double get progress {
    final byTasks = tasksToday / targetTasks;
    final byLesson = lessonsToday >= 1 ? 1.0 : 0.0;
    final value = byTasks > byLesson ? byTasks : byLesson;
    return value.clamp(0.0, 1.0);
  }

  static const empty = DailyGoal(tasksToday: 0, lessonsToday: 0);
}

class DashboardData {
  const DashboardData({
    required this.lessons,
    required this.completedLessonIds,
    required this.plannedTotal,
    required this.dueCount,
    required this.stats,
    required this.dailyGoal,
  });

  final List<Lesson> lessons;
  final Set<String> completedLessonIds;
  final int plannedTotal;
  final int dueCount;
  final ProfileStats stats;
  final DailyGoal dailyGoal;

  int get completedLessons => completedLessonIds.length;

  int get actualTotal => lessons.length;

  double get progress =>
      plannedTotal == 0 ? 0 : (completedLessons / plannedTotal).clamp(0.0, 1.0);

  Lesson? get nextLesson {
    for (final lesson in lessons) {
      if (!completedLessonIds.contains(lesson.id)) return lesson;
    }
    return null;
  }

  CefrLevel get currentLevel => nextLesson?.level ??
      (lessons.isEmpty ? CefrLevel.a1 : lessons.last.level);

  List<Lesson> get b1Lessons =>
      lessons.where((lesson) => lesson.level == CefrLevel.b1).toList(growable: false);

  int get b1Total => b1Lessons.length;

  int get b1Completed =>
      b1Lessons.where((lesson) => completedLessonIds.contains(lesson.id)).length;

  bool get b1TestUnlocked => b1Total > 0 && b1Completed == b1Total;

  double get b1Progress => b1Total == 0 ? 0 : b1Completed / b1Total;
}

class WeakWord {
  const WeakWord({required this.wordId, required this.card});

  final String wordId;
  final SrsCard card;
}
