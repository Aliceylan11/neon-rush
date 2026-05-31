import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'road.dart';

/// Rakip AI araba. Pist boyunca kendi şeritinde, sabit hızda ilerler.
/// Gerçek araba sprite'ı (Gemini) ile çizilir; perspektifte ölçeklenir.
class Rival implements RoadSprite {
  Rival({
    required this.z,
    required this.offset,
    required this.speed,
    required this.color,
    this.image,
  });

  @override
  double z;

  @override
  final double offset;

  final double speed;
  final Color color;
  final ui.Image? image;

  double hitTime = 0; // vurulunca yavaşlama süresi
  void hit() => hitTime = 2.0;

  void update(double dt, double trackLength) {
    final s = hitTime > 0 ? speed * 0.3 : speed;
    z = (z + s * dt) % trackLength;
    if (hitTime > 0) hitTime -= dt;
  }

  @override
  void draw(Canvas canvas, double x, double y, double roadHalfWidth,
      double clip) {
    final img = image;
    final w = (roadHalfWidth * 0.62).clamp(2.0, 2000.0);
    if (w < 2) return;
    final aspect = img != null ? img.height / img.width : 0.85;
    final h = w * aspect;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-100000, -100000, 100000, clip + 1));

    // Yol gölgesi
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w * 0.92, height: h * 0.12),
      Paint()..color = Colors.black.withValues(alpha: 0.4),
    );

    if (img != null) {
      final dst = Rect.fromLTWH(x - w / 2, y - h, w, h);
      final src =
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      // Renk varyasyonu için hafif tint
      canvas.drawImageRect(
        img,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(
              color.withValues(alpha: 0.35), BlendMode.srcATop),
      );
      // Vurulunca kırmızı yanıp söner
      if (hitTime > 0) {
        canvas.drawImageRect(
          img,
          src,
          dst,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..colorFilter = ColorFilter.mode(
                const Color(0xFFFF1744).withValues(alpha: 0.55),
                BlendMode.srcATop),
        );
      }
    } else {
      // Yedek: basit renkli kutu
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - w / 2, y - h, w, h * 0.8),
            Radius.circular(w * 0.1)),
        Paint()..color = color,
      );
    }

    canvas.restore();
  }
}
