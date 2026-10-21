import 'cefr_level.dart';

class Word {
  const Word({
    required this.id,
    required this.en,
    required this.ru,
    required this.transcription,
    required this.partOfSpeech,
    required this.exampleEn,
    required this.exampleRu,
    required this.lessonId,
    required this.level,
  });

  final String id;
  final String en;
  final String ru;
  final String transcription;
  final String partOfSpeech;
  final String exampleEn;
  final String exampleRu;
  final String lessonId;
  final CefrLevel level;

  factory Word.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('vocabulary: поле "$key" обязательно');
      }
      return value;
    }

    return Word(
      id: read('id'),
      en: read('en'),
      ru: read('ru'),
      transcription: read('transcription'),
      partOfSpeech: read('part_of_speech'),
      exampleEn: read('example_en'),
      exampleRu: read('example_ru'),
      lessonId: read('lesson_id'),
      level: CefrLevel.fromString(read('level')),
    );
  }
}

class VocabularyPack {
  const VocabularyPack({required this.version, required this.words});

  final int version;
  final List<Word> words;

  factory VocabularyPack.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'];
    if (rawWords is! List) {
      throw const FormatException('vocabulary: отсутствует массив words');
    }
    return VocabularyPack(
      version: (json['version'] as num?)?.toInt() ?? 1,
      words: rawWords
          .map((item) => Word.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}
