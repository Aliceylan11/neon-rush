import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'mods.dart';
import 'player_car.dart';
import 'race_type.dart';
import 'rival.dart';
import 'road.dart';

class RacingGame extends FlameGame with KeyboardEvents {
  RacingGame({
    required this.raceType,
    required this.onExit,
    this.playerCarAsset = 'car.png',
  });

  final RaceType raceType;
  final VoidCallback onExit; // menüye dön
  final String playerCarAsset; // garajda seçilen araba

  late final Road road;
  final List<Rival> rivals = [];
  ui.Image? carImage; // rakiplerin arabası (siyah)
  ui.Image? playerImage; // oyuncunun seçtiği araba

  // Yarış durumu
  bool finished = false;
  double totalTime = 0; // toplam yarış süresi
  double raceTime = 0; // yıkım modunda kalan süre

  final List<Pickup> pickups = []; // yoldaki toplanabilir küreler
  final List<Mod> mods = []; // elde tutulan modlar (max 3)

  // Fizik durumu
  double position = 0; // kat edilen mesafe (z)
  double playerX = 0; // -1..1 yanal konum (duvarla sınırlı)
  double speed = 0;
  double crashFlash = 0; // duvara çarpma görsel geri bildirimi (0..1)
  double _engAcc = 0; // motor sesi seviye güncelleme sayacı
  double _crashCd = 0; // çarpma sesi bekleme süresi

  // Aktif mod efektleri (kalan saniye)
  double nitroTime = 0;
  double shieldTime = 0;
  double shockTime = 0; // şok dalgası görsel
  double boltTime = 0; // mermi namlu parlaması

  // Girdiler — dokunmatik butonlar
  bool btnLeft = false;
  bool btnRight = false;
  bool btnGas = false;
  bool btnBrake = false;
  bool btnUse = false;
  // Girdiler — klavye
  bool _kL = false;
  bool _kR = false;
  bool _kG = false;
  bool _kB = false;
  bool _kU = false;
  bool _usePrev = false; // "kullan" kenar tespiti

  bool get _left => _kL || btnLeft;
  bool get _right => _kR || btnRight;
  bool get _gas => _kG || btnGas;
  bool get _brake => _kB || btnBrake;
  bool get _use => _kU || btnUse;

  // HUD durumu
  final ValueNotifier<int> lap = ValueNotifier(0);
  final ValueNotifier<double> currentLap = ValueNotifier(0);
  final ValueNotifier<double?> bestLap = ValueNotifier(null);
  final ValueNotifier<int> speedKmh = ValueNotifier(0);
  final ValueNotifier<List<Mod>> modsHud = ValueNotifier([]);
  final ValueNotifier<int> wrecks = ValueNotifier(0); // devirilen rakip
  final ValueNotifier<double> timeLeft = ValueNotifier(0); // yıkım geri sayım

  // Sabitler
  static const double maxSpeed = Road.segmentLength * 60; // ~12000
  static const double _accel = maxSpeed / 5;
  static const double _braking = -maxSpeed;
  static const double _decel = -maxSpeed / 5;
  static const double _centrifugal = 0.3;

  double get speedPercent => (speed / maxSpeed).clamp(0.0, 1.0);
  double get steerInput => (_right ? 1.0 : 0.0) - (_left ? 1.0 : 0.0);

  bool _started = false;
  double _curLapTime = 0;

  @override
  Color backgroundColor() => const Color(0xFF07021A);

  @override
  Future<void> onLoad() async {
    road = Road()..build(math.Random().nextInt(Road.trackCount));
    carImage = await images.load('car.png');
    playerImage = playerCarAsset == 'car.png'
        ? carImage
        : await images.load(playerCarAsset);
    add(RoadComponent(this)..priority = 0);
    add(PlayerCar(this)..priority = 10);
    if (raceType.hasRivals) _spawnRivals();
    if (raceType.hasPickups) _spawnPickups();
    raceTime = raceType.timeLimit;
    timeLeft.value = raceTime;
    audio.startEngine();
    audio.startBgm();
  }

  @override
  void onRemove() {
    audio.stopEngine();
    audio.stopBgm();
    super.onRemove();
  }

  static const List<Color> _rivalColors = [
    Color(0xFF00E5FF), // cyan
    Color(0xFFFFEA00), // sarı
    Color(0xFF76FF03), // yeşil
    Color(0xFFFF9100), // turuncu
    Color(0xFFE040FB), // mor
    Color(0xFFFFFFFF), // beyaz
  ];

  void _spawnRivals() {
    final rng = math.Random(7);
    const count = 12;
    const lanes = [-0.62, 0.0, 0.62];
    for (var i = 0; i < count; i++) {
      rivals.add(Rival(
        z: (i / count) * road.trackLength + rng.nextDouble() * 400,
        offset: lanes[rng.nextInt(lanes.length)],
        speed: maxSpeed * (0.48 + rng.nextDouble() * 0.24),
        color: _rivalColors[i % _rivalColors.length],
        image: carImage,
      ));
    }
  }

  void _spawnPickups() {
    final rng = math.Random(21);
    const lanes = [-0.6, 0.0, 0.6];
    var z = 6000.0;
    while (z < road.trackLength - 1500) {
      pickups.add(Pickup(
        z: z,
        offset: lanes[rng.nextInt(lanes.length)],
        mod: Mod.values[rng.nextInt(Mod.values.length)],
      ));
      z += 18000 + rng.nextDouble() * 12000; // iyice seyrek
    }
  }

  double get _playerTrackZ => (position + Road.playerZ) % road.trackLength;

  double _wrapDz(double dz) {
    final half = road.trackLength / 2;
    if (dz > half) dz -= road.trackLength;
    if (dz < -half) dz += road.trackLength;
    return dz;
  }

  void useMod() {
    if (mods.isEmpty) return;
    final m = mods.removeAt(0);
    modsHud.value = List.of(mods);
    switch (m) {
      case Mod.nitro:
        nitroTime = 2.5;
        audio.sfx('nitro.wav', volume: 0.6);
      case Mod.shield:
        shieldTime = 5.0;
        audio.sfx('shield.wav', volume: 0.5);
      case Mod.bolt:
        _fireBolt();
        audio.sfx('bolt.wav', volume: 0.6);
      case Mod.shockwave:
        _shockwave();
        audio.sfx('shock.wav', volume: 0.6);
    }
  }

  void _onCrash() {
    if (_crashCd <= 0) {
      audio.sfx('crash.wav', volume: 0.7);
      _crashCd = 0.4;
    }
  }

  void _fireBolt() {
    boltTime = 0.35;
    Rival? target;
    var best = double.infinity;
    for (final r in rivals) {
      final dz = _wrapDz(r.z - _playerTrackZ);
      if (dz > 0 && dz < best) {
        best = dz;
        target = r;
      }
    }
    target?.hit();
    if (target != null) wrecks.value++;
  }

  void _shockwave() {
    shockTime = 0.5;
    for (final r in rivals) {
      if (_wrapDz(r.z - _playerTrackZ).abs() < Road.segmentLength * 16) {
        r.hit();
        wrecks.value++;
      }
    }
  }

  void _checkPickups(double dt) {
    for (final p in pickups) {
      p.update(dt);
      if (!p.active) continue;
      final dz = _wrapDz(p.z - _playerTrackZ);
      if (dz.abs() < Road.segmentLength * 1.5 &&
          (p.offset - playerX).abs() < 0.5) {
        if (mods.length < 3) {
          mods.add(p.mod);
          modsHud.value = List.of(mods);
          audio.sfx('pickup.wav', volume: 0.55);
          p.active = false;
          p.respawn = 6.0;
        }
      }
    }
  }

  void _finish() {
    if (finished) return;
    finished = true;
    audio.sfx('finish.wav', volume: 0.8);
    overlays.add('results');
  }

  /// Yarışı baştan başlat (sonuç ekranındaki "Tekrar").
  void restart() {
    overlays.remove('results');
    finished = false;
    position = 0;
    speed = 0;
    playerX = 0;
    crashFlash = 0;
    nitroTime = shieldTime = shockTime = boltTime = 0;
    _started = false;
    _curLapTime = 0;
    totalTime = 0;
    lap.value = 0;
    bestLap.value = null;
    currentLap.value = 0;
    speedKmh.value = 0;
    mods.clear();
    modsHud.value = [];
    wrecks.value = 0;
    raceTime = raceType.timeLimit;
    timeLeft.value = raceTime;
    rivals.clear();
    pickups.clear();
    if (raceType.hasRivals) _spawnRivals();
    if (raceType.hasPickups) _spawnPickups();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (finished) return; // yarış bitti — dondur

    final dx = dt * 2 * speedPercent;
    if (_left) playerX -= dx;
    if (_right) playerX += dx;

    // Virajda merkezkaç kuvvet
    final seg = road.findSegment(position + Road.playerZ);
    playerX -= dx * speedPercent * seg.curve * _centrifugal;

    // Mod kullanımı (basışta bir kez)
    if (_use && !_usePrev) useMod();
    _usePrev = _use;

    // Gaz / fren / yavaşlama (Nitro = otomatik güçlü hızlanma)
    final boosting = nitroTime > 0;
    if (boosting) {
      speed += _accel * 2.2 * dt;
    } else if (_gas) {
      speed += _accel * dt;
    } else if (_brake) {
      speed += _braking * dt;
    } else {
      speed += _decel * dt;
    }
    speed = speed.clamp(0.0, boosting ? maxSpeed * 1.5 : maxSpeed);

    // Mod zamanlayıcıları
    if (nitroTime > 0) nitroTime = math.max(0, nitroTime - dt);
    if (shieldTime > 0) shieldTime = math.max(0, shieldTime - dt);
    if (shockTime > 0) shockTime = math.max(0, shockTime - dt);
    if (boltTime > 0) boltTime = math.max(0, boltTime - dt);

    // Yol kenarı duvarları: araba yoldan çıkamaz, duvara sürtünce hız keser
    const wall = 1.0;
    if (playerX < -wall) {
      playerX = -wall;
      speed *= 0.88; // çarpma — hız kesilir
      crashFlash = 1.0;
      _onCrash();
    } else if (playerX > wall) {
      playerX = wall;
      speed *= 0.88;
      crashFlash = 1.0;
      _onCrash();
    }
    crashFlash = (crashFlash - dt * 3).clamp(0.0, 1.0);

    if (!_started && speed > 0) _started = true;

    // Tur tespiti (mesafe katlarını geçince)
    if (_started) {
      _curLapTime += dt;
      totalTime += dt;
      currentLap.value = _curLapTime;
    }

    // İlerle ve tur sonunda başa sar — pozisyon HER ZAMAN [0, trackLength)
    position += speed * dt;
    if (position >= road.trackLength) {
      position -= road.trackLength;
      if (_started) {
        lap.value += 1;
        if (bestLap.value == null || _curLapTime < bestLap.value!) {
          bestLap.value = _curLapTime;
        }
        _curLapTime = 0;
        audio.sfx('lap.wav', volume: 0.5);
        if (raceType.finishByLaps && lap.value >= raceType.lapTarget) {
          _finish();
        }
      }
    }

    for (final r in rivals) {
      r.update(dt, road.trackLength);
    }
    _checkCollisions();
    _checkPickups(dt);

    if (raceType.timeLimit > 0 && _started) {
      raceTime -= dt;
      timeLeft.value = raceTime.clamp(0.0, raceType.timeLimit);
      if (raceTime <= 0) _finish();
    }

    // Motor sesi seviyesini hıza göre güncelle (yumuşatılmış)
    _engAcc += dt;
    if (_engAcc >= 0.1) {
      _engAcc = 0;
      audio.setEngineVolume(0.1 + 0.45 * speedPercent);
    }
    if (_crashCd > 0) _crashCd -= dt;

    speedKmh.value = (speedPercent * 300).round();
  }

  void _checkCollisions() {
    for (final r in rivals) {
      final dz = _wrapDz(r.z - _playerTrackZ);
      if (dz.abs() < Road.segmentLength * 1.3 &&
          (r.offset - playerX).abs() < 0.55) {
        if (shieldTime > 0) {
          r.hit(); // kalkanla rakibi savur, ceza yok
        } else {
          if (speed > r.speed) speed = r.speed * 0.82; // arkasına takıl
          playerX += playerX < r.offset ? -0.05 : 0.05; // yana savrul
          playerX = playerX.clamp(-1.0, 1.0);
        }
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    bool any(List<LogicalKeyboardKey> keys) => keys.any(keysPressed.contains);
    _kG = any([LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW]);
    _kB = any([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS]);
    _kL = any([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA]);
    _kR = any([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD]);
    _kU = any([LogicalKeyboardKey.space, LogicalKeyboardKey.enter]);
    return KeyEventResult.handled;
  }
}

/// Yolu her karede çizen bileşen (ekran koordinatlarında).
class RoadComponent extends Component {
  RoadComponent(this.game);
  final RacingGame game;

  @override
  void render(Canvas canvas) {
    game.road.render(
      canvas,
      Size(game.size.x, game.size.y),
      game.position,
      game.playerX,
      sprites: [...game.rivals, ...game.pickups],
    );
  }
}
