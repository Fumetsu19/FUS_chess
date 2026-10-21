class ReadingPassage {
  const ReadingPassage({
    required this.id,
    required this.level,
    required this.title,
    required this.text,
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  final String id;
  final String level;
  final String title;
  final String text;
  final String question;
  final List<String> options;
  final int correct;
  final String explanation;

  factory ReadingPassage.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('reading: поле "$key" обязательно');
      }
      return value;
    }

    final options = json['options'];
    final correct = json['correct'];
    if (options is! List ||
        options.length < 2 ||
        correct is! num ||
        correct.toInt() < 0 ||
        correct.toInt() >= options.length) {
      throw FormatException('reading ${json['id']}: некорректные options/correct');
    }
    return ReadingPassage(
      id: read('id'),
      level: read('level'),
      title: read('title'),
      text: read('text'),
      question: read('question'),
      options: options.map((item) => '$item').toList(growable: false),
      correct: correct.toInt(),
      explanation: read('explanation'),
    );
  }
}

class ReadingPack {
  const ReadingPack({required this.version, required this.passages});

  final int version;
  final List<ReadingPassage> passages;

  static const empty = ReadingPack(version: 1, passages: <ReadingPassage>[]);

  factory ReadingPack.fromJson(Map<String, dynamic> json) {
    final raw = json['passages'];
    if (raw is! List) {
      throw const FormatException('b1_reading.json: отсутствует passages');
    }
    return ReadingPack(
      version: (json['version'] as num?)?.toInt() ?? 1,
      passages: raw
          .map(
            (item) => ReadingPassage.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
