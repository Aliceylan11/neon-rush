import 'package:flutter/material.dart';

/// Garajdaki seçilebilir araba görünümleri.
class CarSkin {
  const CarSkin(this.asset, this.name, this.accent);
  final String asset; // assets/images/ altındaki dosya
  final String name;
  final Color accent;
}

const carSkins = <CarSkin>[
  CarSkin('car.png', 'Siyah', Color(0xFFE53935)),
  CarSkin('car_blue.png', 'Mavi', Color(0xFF2196F3)),
  CarSkin('car_purple.png', 'Mor', Color(0xFFB14DFF)),
  CarSkin('car_red.png', 'Kırmızı', Color(0xFFFF1744)),
  CarSkin('car_white.png', 'Beyaz', Color(0xFFB0BEC5)),
];
