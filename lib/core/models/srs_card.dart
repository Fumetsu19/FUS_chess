enum SrsResult {
  correct('correct'),
  wrong('wrong');

  const SrsResult(this.dbValue);

  final String dbValue;

  static SrsResult? fromDb(Object? value) {
    return switch (value) {
      'correct' => SrsResult.correct,
      'wrong' => SrsResult.wrong,
      _ => null,
    };
  }
}

class SrsCard {
  const SrsCard({
    required this.wordId,
    required this.intervalDays,
    required this.ease,
    required this.reviews,
    required this.nextReviewAt,
    required this.lastResult,
  });

  final String wordId;
  final int intervalDays;
  final double ease;
  final int reviews;
  final DateTime nextReviewAt;
  final SrsResult? lastResult;

  bool get learned => reviews >= 1 && lastResult == SrsResult.correct;

  bool isDue(DateTime now) => !nextReviewAt.isAfter(now);

  SrsCard copyWith({
    int? intervalDays,
    double? ease,
    int? reviews,
    DateTime? nextReviewAt,
    SrsResult? lastResult,
    bool clearLastResult = false,
  }) {
    return SrsCard(
      wordId: wordId,
      intervalDays: intervalDays ?? this.intervalDays,
      ease: ease ?? this.ease,
      reviews: reviews ?? this.reviews,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
    );
  }

  factory SrsCard.fromMap(Map<String, Object?> map) {
    return SrsCard(
      wordId: map['word_id']! as String,
      intervalDays: (map['interval_days']! as num).toInt(),
      ease: (map['ease']! as num).toDouble(),
      reviews: (map['reviews']! as num).toInt(),
      nextReviewAt: DateTime.parse(map['next_review_at']! as String).toLocal(),
      lastResult: SrsResult.fromDb(map['last_result']),
    );
  }
}
