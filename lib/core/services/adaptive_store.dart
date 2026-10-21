import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Вспомогательная адаптивность, которую нельзя хранить в утверждённой DDL.
///
/// DDL `srs_cards` не содержит счётчика ошибок за 7 дней, а `lesson_progress`
/// — серии MC-ответов. Поэтому эти небольшие журналы лежат в
/// shared_preferences; основной прогресс по-прежнему в SQLite.
class AdaptiveStore {
  AdaptiveStore(this._prefs);

  final SharedPreferences _prefs;

  static const _wrongLogKey = 'adaptive.wrong_log.v1';
  static const _mcStreakKey = 'adaptive.mc_streak.v1';
  static const _fillModeKey = 'adaptive.fill_mode.v1';
  static const adaptiveThreshold = 5;

  Map<String, List<String>> _loadWrongLog() {
    final raw = _prefs.getString(_wrongLogKey);
    if (raw == null || raw.isEmpty) return <String, List<String>>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, List<String>>{};
      return <String, List<String>>{
        for (final entry in decoded.entries)
          if (entry.value is List)
            '${entry.key}': (entry.value as List)
                .whereType<String>()
                .toList(growable: false),
      };
    } on FormatException {
      return <String, List<String>>{};
    }
  }

  Future<void> recordWrong(String wordId, {DateTime? now}) async {
    final log = _loadWrongLog();
    final moments = <String>[...?log[wordId]];
    moments.add((now ?? DateTime.now()).toUtc().toIso8601String());
    if (moments.length > 30) {
      moments.removeRange(0, moments.length - 30);
    }
    log[wordId] = moments;
    await _prefs.setString(_wrongLogKey, jsonEncode(log));
  }

  Future<int> wrongCount(String wordId, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now())
        .toUtc()
        .subtract(const Duration(days: 7));
    final moments = _loadWrongLog()[wordId] ?? const <String>[];
    var count = 0;
    for (final raw in moments) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null && parsed.isAfter(cutoff)) count++;
    }
    return count;
  }

  Future<Map<String, int>> wrongCounts({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now())
        .toUtc()
        .subtract(const Duration(days: 7));
    final log = _loadWrongLog();
    final result = <String, int>{};
    for (final entry in log.entries) {
      var count = 0;
      for (final raw in entry.value) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null && parsed.isAfter(cutoff)) count++;
      }
      if (count > 0) result[entry.key] = count;
    }
    return result;
  }

  Future<int> mcStreak(String lessonId) async {
    final raw = _prefs.getString(_mcStreakKey);
    if (raw == null) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded[lessonId] is num) {
        return (decoded[lessonId]! as num).toInt();
      }
    } on FormatException {
      return 0;
    }
    return 0;
  }

  Future<void> recordMcResult(
    String lessonId, {
    required bool firstTryCorrect,
  }) async {
    final raw = _prefs.getString(_mcStreakKey);
    Map<String, dynamic> streaks = <String, dynamic>{};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          streaks = decoded.map((key, value) => MapEntry('$key', value));
        }
      } on FormatException {
        streaks = <String, dynamic>{};
      }
    }
    final current = (streaks[lessonId] as num?)?.toInt() ?? 0;
    final next = firstTryCorrect ? current + 1 : 0;
    streaks[lessonId] = next;
    await _prefs.setString(_mcStreakKey, jsonEncode(streaks));
    if (next >= adaptiveThreshold) {
      final modes = await _fillModes();
      modes[lessonId] = true;
      await _prefs.setString(_fillModeKey, jsonEncode(modes));
    }
  }

  Future<bool> prefersFillBlank(String lessonId) async {
    return (await _fillModes())[lessonId] ?? false;
  }

  Future<Map<String, bool>> _fillModes() async {
    final raw = _prefs.getString(_fillModeKey);
    if (raw == null) return <String, bool>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, bool>{};
      return <String, bool>{
        for (final entry in decoded.entries)
          if (entry.value is bool) '${entry.key}': entry.value! as bool,
      };
    } on FormatException {
      return <String, bool>{};
    }
  }

  Future<void> reset() async {
    await _prefs.remove(_wrongLogKey);
    await _prefs.remove(_mcStreakKey);
    await _prefs.remove(_fillModeKey);
  }
}
