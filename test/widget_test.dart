import 'package:araba_yarisi/game/road.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Road', () {
    final road = Road()..build();

    test('dilimler üretilir', () {
      expect(road.segments.length, greaterThan(100));
    });

    test('pist uzunluğu pozitif', () {
      expect(road.trackLength, greaterThan(0));
    });

    test('findSegment pist boyunca sarmalanır', () {
      final s = road.findSegment(road.trackLength * 2.5);
      expect(road.segments.contains(s), isTrue);
    });

    test('başlangıç çizgisi işaretli', () {
      expect(road.segments.first.start, isTrue);
    });

    test('kamera derinliği pozitif', () {
      expect(Road.cameraDepth, greaterThan(0));
    });
  });
}
