import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'racing_game.dart';

/// Sağ üstte klasik dairesel mini-harita:
/// pist halkası + oyuncu ve tüm rakipler (nokta olarak).
class MiniMap extends Component {
  MiniMap(this.game);

  final RacingGame game;

  @override
  void render(Canvas canvas) {
    final tl = game.road.trackLength;
    if (tl <= 0) return;

    const r = 44.0;
    final center = Offset(game.size.x - r - 18, r + 20);

    // Arka plan disk
    canvas.drawCircle(
        center, r + 8, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawCircle(
      center,
      r + 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white24,
    );
    // Pist halkası (yol)
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = const Color(0xFF49F2FF).withValues(alpha: 0.85),
    );

    Offset onRing(double prog) {
      final a = prog * 2 * math.pi - math.pi / 2; // üst = başlangıç
      return center + Offset(math.cos(a), math.sin(a)) * r;
    }

    // Başlangıç/bitiş işareti (üstte)
    canvas.drawRect(
      Rect.fromCenter(center: onRing(0), width: 5, height: 5),
      Paint()..color = Colors.white,
    );

    // Rakipler
    for (final rv in game.rivals) {
      canvas.drawCircle(
          onRing((rv.z % tl) / tl), 3.5, Paint()..color = rv.color);
    }

    // Oyuncu (parlak + halka)
    final pp = onRing((game.position % tl) / tl);
    canvas.drawCircle(
      pp,
      7,
      Paint()
        ..color = const Color(0xFFFF3DAE).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(pp, 4.5, Paint()..color = Colors.white);
  }
}
