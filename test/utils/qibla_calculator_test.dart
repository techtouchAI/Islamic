import 'package:aldhakereen/utils/qibla_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateQiblaDirection', () {
    test('returns a normalized northeast-to-southeast bearing for Baghdad', () {
      final direction = calculateQiblaDirection(
        latitude: 33.3128,
        longitude: 44.3615,
      );

      expect(direction, inInclusiveRange(180, 220));
    });
  });
}
