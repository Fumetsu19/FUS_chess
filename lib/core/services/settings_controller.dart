import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/engine_difficulty.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs) {
    _themeMode = switch (_prefs.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark,
    };
    _soundEnabled = _prefs.getBool(_soundKey) ?? true;
    _difficulty = EngineDifficulty.fromName(_prefs.getString(_difficultyKey));
  }

  final SharedPreferences _prefs;

  static const _themeKey = 'settings.theme';
  static const _soundKey = 'settings.sound';
  static const _difficultyKey = 'settings.difficulty';

  late ThemeMode _themeMode;
  late bool _soundEnabled;
  late EngineDifficulty _difficulty;

  ThemeMode get themeMode => _themeMode;
  bool get soundEnabled => _soundEnabled;
  EngineDifficulty get difficulty => _difficulty;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_themeKey, mode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> toggleTheme() async {
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setSoundEnabled(bool value) async {
    if (value == _soundEnabled) return;
    _soundEnabled = value;
    notifyListeners();
    await _prefs.setBool(_soundKey, value);
  }

  Future<void> setDifficulty(EngineDifficulty value) async {
    if (value == _difficulty) return;
    _difficulty = value;
    notifyListeners();
    await _prefs.setString(_difficultyKey, value.name);
  }
}
