enum CefrLevel {
  a1('A1'),
  a2('A2'),
  b1('B1');

  const CefrLevel(this.label);

  final String label;

  static CefrLevel fromString(String value) {
    return switch (value.toUpperCase()) {
      'A1' => CefrLevel.a1,
      'A2' => CefrLevel.a2,
      'B1' => CefrLevel.b1,
      _ => throw FormatException('Неизвестный уровень CEFR: $value'),
    };
  }

  int get rank => switch (this) {
        CefrLevel.a1 => 0,
        CefrLevel.a2 => 1,
        CefrLevel.b1 => 2,
      };
}
