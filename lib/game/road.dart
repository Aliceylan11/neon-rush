import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bir 3B noktanın dünya/kamera/ekran koordinatlarını tutar.
class RoadPoint {
  double wx = 0, wy = 0, wz = 0; // dünya
  double cx = 0, cy = 0, cz = 0; // kameraya göre
  double sx = 0, sy = 0, sw = 0, scale = 0; // ekran
}

/// Yol üzerinde perspektifle ölçeklenip çizilen bir nesne (rakip, mod, sahne).
abstract class RoadSprite {
  double get z; // pist boyunca konum
  double get offset; // -1..1 (taşarsa yol kenarı) yanal
  void draw(Canvas canvas, double x, double y, double roadHalfWidth, double clip);
}

/// Yolun tek bir dilimi (yamuk şerit).
class Segment {
  Segment(this.index);
  final int index;
  final RoadPoint p1 = RoadPoint(); // yakın kenar
  final RoadPoint p2 = RoadPoint(); // uzak kenar
  double curve = 0;
  bool dark = false;
  bool start = false; // başlangıç/bitiş çizgisi
  double clip = 0; // sprite kırpma sınırı (tepe ardı gizleme)
  final List<RoadSprite> sprites = [];
}

enum SceneryType { pylon, sign }

/// Pseudo-3D (sahte 3B) yol motoru — OutRun tarzı perspektif projeksiyon.
class Road {
  // --- Sabitler ---
  static const double segmentLength = 200;
  static const double roadWidth = 2000; // merkezden kenara (yarı genişlik)
  static const double cameraHeight = 1600; // daha yüksek = daha "kuş bakışı"
  static const int drawDistance = 240;
  static const int rumbleLength = 3;
  static const int lanes = 3;
  static const double fogDensity = 5;

  static final double cameraDepth =
      1 / math.tan((100 / 2) * math.pi / 180); // FOV 100°
  static double get playerZ => cameraHeight * cameraDepth;

  // --- Neon palet ---
  static const Color _fog = Color(0xFF07021A);
  static const Color _roadLight = Color(0xFF35354A);
  static const Color _roadDark = Color(0xFF2C2C3E);
  static const Color _grassLight = Color(0xFF140A30);
  static const Color _grassDark = Color(0xFF0E0724);
  static const Color _rumbleLight = Color(0xFFFF3DAE); // neon magenta
  static const Color _rumbleDark = Color(0xFFE6E6FF);
  static const Color _lane = Color(0xFF49F2FF); // neon cyan
  static const Color _startColor = Color(0xFFEDEDFF);
  static const Color _edgeCyan = Color(0xFF49F2FF);
  static const Color _edgePurple = Color(0xFF9D4DFF);

  static const List<Color> _neon = [
    Color(0xFF49F2FF),
    Color(0xFFFF3DAE),
    Color(0xFFFFE259),
    Color(0xFF76FF8B),
    Color(0xFFB14DFF),
  ];

  final List<Segment> segments = [];
  double trackLength = 0;

  /// Statik yol kenarı objeleri (direk, tabela...)
  final List<RoadSprite> scenery = [];

  // Parallax arka plan durumu
  double _bgOffset = 0;
  final List<_Building> _skyline = [];
  double _skylineWidth = 0;

  /// Pist ön ayarları: her komut [enter, hold, leave, curve].
  static const List<List<List<double>>> _tracks = [
    // 0 — Dengeli
    [
      [40, 40, 40, 0], [50, 50, 50, -4], [40, 30, 40, 5], [100, 100, 100, 0],
      [50, 50, 50, 4], [30, 30, 30, -5], [40, 40, 40, 2], [40, 40, 40, -2],
      [60, 60, 60, 0],
    ],
    // 1 — Teknik (sık, sert virajlar)
    [
      [30, 20, 30, 0], [30, 20, 30, 5], [25, 20, 25, -5], [30, 20, 30, 4],
      [25, 15, 25, -6], [40, 30, 40, 3], [25, 20, 25, -4], [30, 20, 30, 6],
      [30, 20, 30, -5], [40, 40, 40, 0],
    ],
    // 2 — Hızlı (uzun düzlükler, geniş virajlar)
    [
      [150, 150, 150, 0], [60, 80, 60, 3], [150, 120, 150, 0], [60, 80, 60, -3],
      [120, 120, 120, 0], [50, 60, 50, 2], [150, 150, 150, 0],
    ],
  ];
  static int get trackCount => _tracks.length;

  void build([int trackIndex = 0]) {
    segments.clear();
    scenery.clear();
    _skyline.clear();

    for (final c in _tracks[trackIndex % _tracks.length]) {
      _addRoad(c[0].toInt(), c[1].toInt(), c[2].toInt(), c[3]);
    }

    for (var i = 0; i < segments.length && i < 4; i++) {
      segments[i].start = true;
    }

    trackLength = segments.length * segmentLength;
    _generateScenery();
    _generateSkyline();
  }

  void _addSegment(double curve) {
    final n = segments.length;
    final s = Segment(n);
    s.p1.wz = n * segmentLength;
    s.p2.wz = (n + 1) * segmentLength;
    s.curve = curve;
    s.dark = (n ~/ rumbleLength).isEven;
    segments.add(s);
  }

  void _addRoad(int enter, int hold, int leave, double curve) {
    for (var i = 0; i < enter; i++) {
      _addSegment(_easeIn(0, curve, i / enter));
    }
    for (var i = 0; i < hold; i++) {
      _addSegment(curve);
    }
    for (var i = 0; i < leave; i++) {
      _addSegment(_easeInOut(curve, 0, i / leave));
    }
  }

  void _generateScenery() {
    final rng = math.Random(99);
    var z = 800.0;
    while (z < trackLength - 400) {
      final side = rng.nextBool() ? 1.0 : -1.0;
      final off = side * (1.25 + rng.nextDouble() * 0.5);
      final type = rng.nextInt(3) == 0 ? SceneryType.sign : SceneryType.pylon;
      scenery.add(Scenery(
        z: z,
        offset: off,
        type: type,
        color: _neon[rng.nextInt(_neon.length)],
      ));
      z += 500 + rng.nextDouble() * 700;
    }
  }

  void _generateSkyline() {
    final rng = math.Random(42);
    var total = 0.0;
    for (var i = 0; i < 44; i++) {
      final bw = 30 + rng.nextDouble() * 75;
      final bh = 28 + rng.nextDouble() * 150;
      final color =
          Color.lerp(const Color(0xFF150A2E), const Color(0xFF281152), rng.nextDouble())!;
      final windows = <Offset>[];
      final cols = (bw / 12).floor();
      final rows = (bh / 15).floor();
      for (var c = 0; c < cols; c++) {
        for (var r = 0; r < rows; r++) {
          if (rng.nextDouble() < 0.38) {
            windows.add(Offset((c + 0.5) / cols, (r + 0.4) / rows));
          }
        }
      }
      _skyline.add(_Building(bw, bh, color, windows));
      total += bw;
    }
    _skylineWidth = total;
  }

  double _easeIn(double a, double b, double p) => a + (b - a) * p * p;
  double _easeInOut(double a, double b, double p) =>
      a + (b - a) * (-math.cos(p * math.pi) / 2 + 0.5);

  Segment findSegment(double z) =>
      segments[(z ~/ segmentLength) % segments.length];

  void _project(RoadPoint p, double camX, double camY, double camZ,
      double width, double height) {
    p.cx = p.wx - camX;
    p.cy = p.wy - camY;
    p.cz = p.wz - camZ;
    p.scale = cameraDepth / p.cz;
    p.sx = (width / 2) + (p.scale * p.cx * width / 2);
    p.sy = (height / 2) - (p.scale * p.cy * height / 2);
    p.sw = p.scale * roadWidth * width / 2;
  }

  double _expFog(double d, double density) =>
      1 / math.pow(math.e, d * d * density);

  /// Tüm sahneyi çizer. [position] = kat edilen mesafe, [playerX] = -1..1 yanal.
  /// [sprites] = dinamik nesneler (rakipler).
  void render(Canvas canvas, Size size, double position, double playerX,
      {List<RoadSprite> sprites = const []}) {
    final width = size.width;
    final height = size.height;

    final base = findSegment(position);

    // Parallax arka plan (viraja/yanal konuma göre kayar)
    final targetBg = base.curve * 60 + playerX * 90;
    _bgOffset += (targetBg - _bgOffset) * 0.06;
    _drawSky(canvas, size, _bgOffset);

    // Sprite'ları dilimlere dağıt (sahne + dinamik)
    for (final s in segments) {
      s.sprites.clear();
    }
    for (final sp in scenery) {
      findSegment(sp.z).sprites.add(sp);
    }
    for (final sp in sprites) {
      findSegment(sp.z).sprites.add(sp);
    }

    final basePercent = (position % segmentLength) / segmentLength;
    final playerSeg = findSegment(position + playerZ);
    final playerPercent =
        ((position + playerZ) % segmentLength) / segmentLength;
    final playerY = _interp(playerSeg.p1.wy, playerSeg.p2.wy, playerPercent);

    var maxy = height;
    var x = 0.0;
    var dx = -(base.curve * basePercent);

    // 1. geçiş: yol (yakından uzağa, kırpmayla)
    for (var n = 0; n < drawDistance; n++) {
      final seg = segments[(base.index + n) % segments.length];
      seg.clip = maxy;
      final looped = seg.index < base.index;
      final fog = _expFog(n / drawDistance, fogDensity);
      final camZ = position - (looped ? trackLength : 0);

      _project(seg.p1, (playerX * roadWidth) - x, playerY + cameraHeight, camZ,
          width, height);
      _project(seg.p2, (playerX * roadWidth) - x - dx, playerY + cameraHeight,
          camZ, width, height);

      x += dx;
      dx += seg.curve;

      if (seg.p1.cz <= cameraDepth ||
          seg.p2.sy >= seg.p1.sy ||
          seg.p2.sy >= maxy) {
        continue;
      }

      _renderSegment(canvas, width, seg, fog);
      maxy = seg.p2.sy;
    }

    // 2. geçiş: sprite'lar (uzaktan yakına, üst üste binme doğru olsun)
    for (var n = drawDistance - 1; n >= 0; n--) {
      final seg = segments[(base.index + n) % segments.length];
      if (seg.sprites.isEmpty || seg.p1.cz <= cameraDepth) continue;
      final sw = seg.p1.sw;
      if (sw <= 0) continue;
      for (final sp in seg.sprites) {
        sp.draw(canvas, seg.p1.sx + sw * sp.offset, seg.p1.sy, sw, seg.clip);
      }
    }
  }

  void _drawSky(Canvas canvas, Size size, double bgOffset) {
    final w = size.width;
    final h = size.height;
    final horizonY = h * 0.5;

    // Gökyüzü gradyanı
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizonY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF06021A), Color(0xFF1B0B3A), Color(0xFF3E1C64)],
          stops: [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, horizonY)),
    );
    // Ufuk altı emniyet dolgusu (yol kaplayana dek)
    canvas.drawRect(
        Rect.fromLTWH(0, horizonY, w, h - horizonY), Paint()..color = _fog);

    // Sentetik (synthwave) güneş
    final sunX = w * 0.5 + bgOffset * 0.5;
    final sunR = h * 0.17;
    final sunCenter = Offset(sunX, horizonY - sunR * 0.35);
    canvas.drawCircle(
      sunCenter,
      sunR * 1.6,
      Paint()
        ..color = const Color(0xFFFF2D95).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
    canvas.drawCircle(
      sunCenter,
      sunR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFFFE259), Color(0xFFFF5FB0)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: sunR)),
    );
    // Güneşin alt yarısında yatay kesikler
    final cut = Paint()..color = _fog;
    for (var i = 0; i < 4; i++) {
      final yy = sunCenter.dy + sunR * 0.28 + i * (sunR * 0.18);
      canvas.drawRect(
          Rect.fromLTWH(sunX - sunR, yy, sunR * 2, sunR * 0.07), cut);
    }

    _drawSkyline(canvas, w, horizonY, bgOffset);

    // Ufuk ışıması
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY - 2, w, 4),
      Paint()
        ..color = _edgeCyan.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawSkyline(Canvas canvas, double w, double horizonY, double bgOffset) {
    if (_skyline.isEmpty || _skylineWidth <= 0) return;
    var shift = (bgOffset * 0.8) % _skylineWidth;
    if (shift > 0) shift -= _skylineWidth;
    var x = shift;
    var i = 0;
    while (x < w + 120) {
      final b = _skyline[i % _skyline.length];
      final top = horizonY - b.h;
      canvas.drawRect(Rect.fromLTWH(x, top, b.w, b.h), Paint()..color = b.color);
      canvas.drawRect(Rect.fromLTWH(x, top, b.w, 2),
          Paint()..color = _edgeCyan.withValues(alpha: 0.4));
      final wp = Paint()..color = const Color(0xFFFFE259).withValues(alpha: 0.7);
      for (final o in b.windows) {
        canvas.drawRect(
            Rect.fromLTWH(x + o.dx * b.w, top + o.dy * b.h, 2.5, 3), wp);
      }
      x += b.w;
      i++;
    }
  }

  void _renderSegment(Canvas canvas, double width, Segment seg, double fog) {
    final x1 = seg.p1.sx, y1 = seg.p1.sy, w1 = seg.p1.sw;
    final x2 = seg.p2.sx, y2 = seg.p2.sy, w2 = seg.p2.sw;

    final road = seg.start
        ? _startColor
        : _fogged(seg.dark ? _roadDark : _roadLight, fog);
    final grass = _fogged(seg.dark ? _grassDark : _grassLight, fog);
    final rumble = _fogged(seg.dark ? _rumbleDark : _rumbleLight, fog);

    // Çim (tam genişlikte bant: uzak y2 -> yakın y1)
    _quad(canvas, 0, y2, width, y2, width, y1, 0, y1, grass);

    // Yol kenarı şeritleri (rumble)
    final r1 = w1 / 6, r2 = w2 / 6;
    _quad(canvas, x1 - w1 - r1, y1, x1 - w1, y1, x2 - w2, y2, x2 - w2 - r2, y2,
        rumble);
    _quad(canvas, x1 + w1 + r1, y1, x1 + w1, y1, x2 + w2, y2, x2 + w2 + r2, y2,
        rumble);

    // Asfalt
    _quad(canvas, x1 - w1, y1, x1 + w1, y1, x2 + w2, y2, x2 - w2, y2, road);

    // Parlayan iç kenar çizgisi (neon)
    if (!seg.start) {
      final edge = _fogged(seg.dark ? _edgePurple : _edgeCyan, fog);
      final e1 = w1 * 0.05, e2 = w2 * 0.05;
      _quad(canvas, x1 - w1, y1, x1 - w1 + e1, y1, x2 - w2 + e2, y2, x2 - w2, y2,
          edge);
      _quad(canvas, x1 + w1 - e1, y1, x1 + w1, y1, x2 + w2, y2, x2 + w2 - e2, y2,
          edge);
    }

    // Şerit çizgileri (yalnız açık dilimlerde -> kesikli neon cyan)
    if (!seg.dark && !seg.start) {
      final lane = _fogged(_lane, fog);
      final l1 = w1 / 32, l2 = w2 / 32;
      final lanew1 = w1 * 2 / lanes, lanew2 = w2 * 2 / lanes;
      var lanex1 = x1 - w1 + lanew1, lanex2 = x2 - w2 + lanew2;
      for (var i = 1; i < lanes; i++) {
        _quad(canvas, lanex1 - l1 / 2, y1, lanex1 + l1 / 2, y1, lanex2 + l2 / 2,
            y2, lanex2 - l2 / 2, y2, lane);
        lanex1 += lanew1;
        lanex2 += lanew2;
      }
    }
  }

  Color _fogged(Color c, double fog) =>
      Color.lerp(_fog, c, fog.clamp(0.0, 1.0))!;

  double _interp(double a, double b, double p) => a + (b - a) * p;

  void _quad(Canvas canvas, double x1, double y1, double x2, double y2,
      double x3, double y3, double x4, double y4, Color color) {
    final path = Path()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..lineTo(x4, y4)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
}

/// Arka plan şehir silüetindeki bir bina.
class _Building {
  _Building(this.w, this.h, this.color, this.windows);
  final double w;
  final double h;
  final Color color;
  final List<Offset> windows; // göreli (0..1) pencere konumları
}

/// Yol kenarı neon objesi (direk veya tabela).
class Scenery implements RoadSprite {
  Scenery({
    required this.z,
    required this.offset,
    required this.type,
    required this.color,
  });

  @override
  final double z;
  @override
  final double offset;
  final SceneryType type;
  final Color color;

  @override
  void draw(Canvas canvas, double x, double y, double roadHalfWidth,
      double clip) {
    final s = roadHalfWidth;
    if (s < 1) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-100000, -100000, 100000, clip + 1));

    if (type == SceneryType.pylon) {
      final poleH = s * 1.7;
      final poleW = (s * 0.06).clamp(1.5, 50.0);
      canvas.drawRect(
        Rect.fromLTWH(x - poleW / 2, y - poleH, poleW, poleH),
        Paint()..color = const Color(0xFF20143A),
      );
      final ballR = (s * 0.16).clamp(2.0, 120.0);
      canvas.drawCircle(
        Offset(x, y - poleH),
        ballR * 1.7,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ballR * 0.7),
      );
      canvas.drawCircle(Offset(x, y - poleH), ballR, Paint()..color = color);
    } else {
      final bw = s * 1.0;
      final bh = s * 0.55;
      final top = y - s * 1.55;
      final legW = (s * 0.06).clamp(1.5, 50.0);
      // Ayak
      canvas.drawRect(
        Rect.fromLTWH(x - legW / 2, top + bh, legW, s),
        Paint()..color = const Color(0xFF20143A),
      );
      // Pano arkası glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, top + bh / 2), width: bw * 1.15, height: bh * 1.15),
          Radius.circular(s * 0.06),
        ),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, (s * 0.12).clamp(2.0, 40.0)),
      );
      // Pano
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - bw / 2, top, bw, bh), Radius.circular(s * 0.05)),
        Paint()..color = const Color(0xFF120A24),
      );
      // Neon çerçeve
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - bw / 2, top, bw, bh), Radius.circular(s * 0.05)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (s * 0.04).clamp(1.0, 14.0)
          ..color = color,
      );
    }

    canvas.restore();
  }
}
