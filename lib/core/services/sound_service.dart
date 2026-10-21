import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum SoundEffect {
  move('move.wav'),
  capture('capture.wav'),
  check('check.wav'),
  mate('mate.wav');

  const SoundEffect(this.file);

  final String file;
}

class SoundService {
  AudioPlayer? _player;
  Future<void>? _ready;
  bool enabled = true;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _player = player;
    _ready = _prepare(player);
    return player;
  }

  Future<void> _prepare(AudioPlayer player) async {
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
    } catch (error) {
      debugPrint('SoundService: инициализация без звука: $error');
    }
  }

  void setEnabled(bool value) {
    enabled = value;
  }

  Future<void> play(SoundEffect effect) async {
    if (!enabled) return;
    try {
      final player = _ensurePlayer();
      await _ready;
      await player.stop();
      await player.play(
        AssetSource('sounds/${effect.file}'),
        volume: 0.55,
      );
    } catch (error) {
      debugPrint('SoundService: не удалось воспроизвести ${effect.file}: $error');
    }
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    _ready = null;
    await player?.dispose();
  }
}
