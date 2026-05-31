import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'road.dart';

/// Güç-up (mod) türleri.
enum Mod { nitro, shield, bolt, shockwave }

extension ModInfo on Mod {
  Color get color => switch (this) {
        Mod.nitro => const Color(0xFF49F2FF),
        Mod.shield => const Color(0xFF76FF8B),
        Mod.bolt => const Color(0xFFFFE259),
        Mod.shockwave => const Color(0xFFFF3DAE),
      };

  IconData get icon => switch (this) {
        Mod.nitro => Icons.bolt,
        Mod.shield => Icons.shield,
        Mod.bolt => Icons.gps_fixed,
        Mod.shockwave => Icons.wifi_tethering,
      };

  String get label => switch (this) {
        Mod.nitro => 'NITRO',
        Mod.shield => 'KALKAN',
        Mod.bolt => 'MERMİ',
        Mod.shockwave => 'ŞOK',
      };
}

/// Bir Material ikonunu canvas'a çizer (merkezlenmiş).
void drawIcon(Canvas canvas, IconData icon, Offset center, double size,
    Color color) {
  final tp = TextPainter(textDirection: TextDirection.ltr)
    ..text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    )
    ..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// Yolda toplanabilen, havada süzülen neon küre. Üzerinde mod ikonu vardır.
/// Toplanınca kaybolur ve [respawn] süresi sonra geri gelir.
class Pickup implements RoadSprite {
  Pickup({required this.z, required this.offset, required this.mod});

  @override
  final double z;
  @override
  final double offset;
  final Mod mod;

  bool active = true;
  double respawn = 0;
  double _t = 0;

  void update(double dt) {
    _t += dt;
    if (!active) {
      respawn -= dt;
      if (respawn <= 0) {
        active = true;
      }
    }
  }

  @override
  void draw(Canvas canvas, double x, double y, double roadHalfWidth,
      double clip) {
    if (!active) return;
    final s = roadHalfWidth;
    final r = (s * 0.20).clamp(3.0, 170.0);
    final cy = y - r * 1.7 - math.sin(_t * 3) * r * 0.25; // yolun üstünde süzülür
    final c = Offset(x, cy);

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-100000, -100000, 100000, clip + 1));

    // Dış parıltı (mod rengi)
    canvas.drawCircle(
      c,
      r * 1.9,
      Paint()
        ..color = mod.color.withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8),
    );
    // Küre (mod rengi)
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(mod.color, Colors.white, 0.5)!, mod.color],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // İkon kontrastı için koyu iç disk
    canvas.drawCircle(c, r * 0.72, Paint()..color = Colors.black.withValues(alpha: 0.4));
    // Mod ikonu (beyaz)
    drawIcon(canvas, mod.icon, c, r * 1.0, Colors.white);

    canvas.restore();
  }
}
