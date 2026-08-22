import 'package:aldhakereen/utils/next_prayer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final morningTimes = <String, DateTime>{
    'imsak': DateTime(2026, 8, 23, 2, 14),
    'fajr': DateTime(2026, 8, 23, 4, 23),
    'dhuhr': DateTime(2026, 8, 23, 12, 8),
    'asr': DateTime(2026, 8, 23, 15, 42),
    'maghrib': DateTime(2026, 8, 23, 18, 31),
    'isha': DateTime(2026, 8, 23, 19, 51),
  };

  group('next prayer for the home card', () {
    test('skips imsak outside Ramadan even when it is the nearest raw time',
        () {
      expect(
        nextPrayerKeyForHome(
          localCivilTimes: morningTimes,
          now: DateTime(2026, 8, 23, 2),
          isRamadan: false,
        ),
        'fajr',
      );
    });

    test('allows imsak during Ramadan and keeps its Arabic label', () {
      expect(
        nextPrayerKeyForHome(
          localCivilTimes: morningTimes,
          now: DateTime(2026, 8, 23, 2),
          isRamadan: true,
        ),
        'imsak',
      );
      expect(prayerDisplayNameAr('imsak'), 'الإمساك');
    });

    test('returns Fajr after the final prayer of the day', () {
      expect(
        nextPrayerKeyForHome(
          localCivilTimes: morningTimes,
          now: DateTime(2026, 8, 23, 22),
          isRamadan: false,
        ),
        'fajr',
      );
    });
  });
}
