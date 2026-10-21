class AnswerChecker {
  const AnswerChecker._();

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[.,!?;:«»"“”…]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
