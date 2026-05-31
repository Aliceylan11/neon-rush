import 'package:flame_audio/flame_audio.dart';

/// Oyun sesleri (flame_audio). Uygulama genelinde tek örnek: [audio].
/// Tüm çağrılar hata-toleranslı (ses olmasa da oyun çalışır).
class GameAudio {
  bool muted = false;
  dynamic _engine; // motor döngüsü için AudioPlayer

  Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'click.wav', 'pickup.wav', 'nitro.wav', 'shield.wav', 'bolt.wav',
        'shock.wav', 'crash.wav', 'lap.wav', 'finish.wav', 'engine.wav',
      ]);
    } catch (_) {}
  }

  void sfx(String name, {double volume = 1.0}) {
    if (muted) return;
    try {
      FlameAudio.play(name, volume: volume);
    } catch (_) {}
  }

  Future<void> startEngine() async {
    if (muted) return;
    try {
      _engine = await FlameAudio.loop('engine.wav', volume: 0.0);
    } catch (_) {}
  }

  void setEngineVolume(double v) {
    try {
      _engine?.setVolume(v.clamp(0.0, 1.0));
    } catch (_) {}
  }

  void stopEngine() {
    try {
      _engine?.stop();
    } catch (_) {}
    _engine = null;
  }

  Future<void> startBgm() async {
    if (muted) return;
    try {
      await FlameAudio.bgm.play('bgm.wav', volume: 0.35);
    } catch (_) {}
  }

  void stopBgm() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }
}

final audio = GameAudio();
