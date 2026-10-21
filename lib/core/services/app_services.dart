import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../models/progress.dart';
import '../repositories/content_repository.dart';
import '../repositories/progress_repository.dart';
import '../repositories/srs_repository.dart';
import '../repositories/stats_repository.dart';
import 'adaptive_store.dart';
import 'settings_controller.dart';
import 'sound_service.dart';
import 'task_picker.dart';

class AppServices {
  AppServices({
    required this.database,
    required this.content,
    required this.progress,
    required this.srs,
    required this.stats,
    required this.adaptive,
    required this.settings,
    required this.sound,
    required this.taskPicker,
  }) {
    _syncSound();
    settings.addListener(_syncSound);
  }

  final AppDatabase database;
  final ContentRepository content;
  final ProgressRepository progress;
  final SrsRepository srs;
  final StatsRepository stats;
  final AdaptiveStore adaptive;
  final SettingsController settings;
  final SoundService sound;
  final TaskPicker taskPicker;

  static Future<AppServices> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase();
    await database.open();
    final content = await ContentRepository.loadFromAssets();
    final adaptive = AdaptiveStore(prefs);
    final settings = SettingsController(prefs);
    final srs = SrsRepository(database);
    final progress = ProgressRepository(database);
    final sound = SoundService()..setEnabled(settings.soundEnabled);
    return AppServices(
      database: database,
      content: content,
      progress: progress,
      srs: srs,
      stats: StatsRepository(database),
      adaptive: adaptive,
      settings: settings,
      sound: sound,
      taskPicker: TaskPicker(
        content: content,
        srs: srs,
        progress: progress,
        adaptive: adaptive,
      ),
    );
  }

  Future<DashboardData> dashboard() async {
    final completed = await progress.completedLessonIds();
    return DashboardData(
      lessons: content.lessons,
      completedLessonIds: completed,
      plannedTotal: content.plannedTotal,
      dueCount: await srs.dueCount(),
      stats: await stats.profileStats(),
      dailyGoal: await stats.dailyGoal(),
    );
  }

  Future<void> resetProgress() async {
    await database.clearAll();
    await adaptive.reset();
  }

  void _syncSound() {
    sound.setEnabled(settings.soundEnabled);
  }

  Future<void> dispose() async {
    settings.removeListener(_syncSound);
    await sound.dispose();
    await database.close();
  }
}
