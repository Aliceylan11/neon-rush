import 'package:flutter/material.dart';

/// Yarış tipleri ve her birinin kuralları.
enum RaceType { lap, timeTrial, endless, destruction }

extension RaceTypeInfo on RaceType {
  String get title => switch (this) {
        RaceType.lap => 'Tur Yarışı',
        RaceType.timeTrial => 'Zaman Yarışı',
        RaceType.endless => 'Sonsuz Sürüş',
        RaceType.destruction => 'Yıkım',
      };

  String get desc => switch (this) {
        RaceType.lap => '3 tur · rakiplerle yarış',
        RaceType.timeTrial => 'Tek başına · en iyi tur',
        RaceType.endless => 'Bitiş yok · serbest sür',
        RaceType.destruction => "Mod'larla rakip devir",
      };

  IconData get icon => switch (this) {
        RaceType.lap => Icons.flag,
        RaceType.timeTrial => Icons.timer,
        RaceType.endless => Icons.all_inclusive,
        RaceType.destruction => Icons.local_fire_department,
      };

  Color get color => switch (this) {
        RaceType.lap => const Color(0xFF49F2FF),
        RaceType.timeTrial => const Color(0xFFFFE259),
        RaceType.endless => const Color(0xFF76FF8B),
        RaceType.destruction => const Color(0xFFFF3DAE),
      };

  /// Bitiş için tur sayısı (0 = tur ile bitmez).
  int get lapTarget => switch (this) {
        RaceType.lap => 3,
        RaceType.timeTrial => 3,
        _ => 0,
      };

  bool get finishByLaps => this == RaceType.lap || this == RaceType.timeTrial;
  bool get hasRivals => this != RaceType.timeTrial;
  bool get hasPickups => this != RaceType.timeTrial;

  /// Süre sınırı (sn); 0 = sınırsız. Yıkım modunda geri sayım.
  double get timeLimit => this == RaceType.destruction ? 75 : 0;
}
