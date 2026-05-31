import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'racing_game.dart';

/// Oyuncunun arabası — gerçek araba sprite'ı (Gemini) + mod efektleri.
class PlayerCar extends Component {
  PlayerCar(this.game);

  final RacingGame game;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;
    final steer = game.steerInput;
    final speedPct = game.speedPercent;

    // Duvara çarpma kırmızı parlaması
    if (game.crashFlash > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color =
              const Color(0xFFFF1744).withValues(alpha: game.crashFlash * 0.28),
      );
    }

    final img = game.playerImage;
    if (img == null) return;

    final carW = math.min(w * 0.20, h * 0.52);
    final carH = carW * (img.height / img.width);

    final bob = math.sin(_t * 26) * 2.0 * speedPct;
    final cx = w / 2 + steer * w * 0.02;
    final cy = h - carH * 0.55 + bob;

    // Nitro hız çizgileri (ufuk noktasından dışarı fışkırır)
    if (game.nitroTime > 0) {
      final vp = Offset(w / 2, h * 0.42);
      final t = (_t * 3) % 1.0;
      final paint = Paint()
        ..color = const Color(0xFF49F2FF).withValues(alpha: 0.45)
        ..strokeWidth = 2;
      for (var i = 0; i < 22; i++) {
        final ang = (i / 22) * 2 * math.pi;
        final d = Offset(math.cos(ang), math.sin(ang));
        final r1 = h * (0.26 + 0.18 * t);
        canvas.drawLine(vp + d * r1, vp + d * (r1 + h * 0.22), paint);
      }
    }

    // Şok dalgası halkası (arabadan dışarı genişler)
    if (game.shockTime > 0) {
      final prog = 1 - (game.shockTime / 0.5);
      canvas.drawCircle(
        Offset(cx, cy),
        prog * w * 0.6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + (1 - prog) * 8
          ..color = const Color(0xFFFF3DAE).withValues(alpha: (1 - prog) * 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(steer * 0.04);

    // Yol gölgesi
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, carH * 0.42), width: carW * 0.9, height: carH * 0.14),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    final dst = Rect.fromCenter(center: Offset.zero, width: carW, height: carH);
    final src =
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    canvas.drawImageRect(
        img, src, dst, Paint()..filterQuality = FilterQuality.medium);

    // Kalkan halkası
    if (game.shieldTime > 0) {
      final pulse = 0.6 + 0.4 * math.sin(_t * 8);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -carH * 0.04),
            width: carW * 1.3,
            height: carH * 1.12),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = carW * 0.05
          ..color = const Color(0xFF76FF8B).withValues(alpha: 0.75 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Mermi namlu parlaması (aracın önünde)
    if (game.boltTime > 0) {
      canvas.drawCircle(
        Offset(0, -carH * 0.5),
        carW * 0.28,
        Paint()
          ..color =
              const Color(0xFFFFE259).withValues(alpha: game.boltTime / 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.restore();
  }
}
