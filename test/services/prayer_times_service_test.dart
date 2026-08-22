import 'package:aldhakereen/models/prayer_location.dart';
import 'package:aldhakereen/services/prayer_times_service.dart';
import 'package:aldhakereen/utils/pray_times.dart';
import 'package:aldhakereen/utils/prayer_time_zone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerTimesService location source', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('selected city is stable and does not depend on device timezone',
        () async {
      final service = PrayerTimesService();
      final location = await service.resolveLocation(
          selectedCity: 'بغداد', refreshGps: false);

      expect(location, isNotNull);
      expect(location!.source, PrayerLocationSource.selectedCity);
      expect(location.latitude, closeTo(33.3128, 0.0001));
      expect(
          location.timeZoneOffsetHours, PrayerTimeZonePolicy.iraqOffsetHours);
    });

    test('GPS failure is explicit and never mislabeled as live GPS', () async {
      final service = PrayerTimesService();
      final location = await service.resolveLocation(
        selectedCity: PrayerTimesService.gpsLocationName,
        refreshGps: true,
      );

      expect(location, isNotNull);
      expect(location!.source, isNot(PrayerLocationSource.gps));
      expect(location.displayName, isNot('الموقع الحالي عبر GPS'));
    });
  });

  group('PrayerTimesService and PrayTimes', () {
    test('returns finite prayer times and uses explicit Iraq timezone', () {
      final service = PrayerTimesService();
      final position = const PrayerLocation(
        latitude: 33.3128,
        longitude: 44.3615,
        source: PrayerLocationSource.selectedCity,
        displayName: 'بغداد',
        timeZoneOffsetHours: 3,
      ).toPosition();
      final date = DateTime.utc(2026, 8, 22);
      final times = service.calculatePrayerTimes(
        position,
        date: date,
        timeZoneOffsetHours: 3,
      );

      expect(times, containsPair('fajr', isA<DateTime>()));
      expect(times, containsPair('dhuhr', isA<DateTime>()));
      expect(times, containsPair('midnight', isA<DateTime>()));
      expect(times.values.every((value) => value.isUtc), isTrue);
    });

    test('Jafari midnight is halfway between sunset and next-day Fajr', () {
      final engine = PrayTimes(PrayerCalculationParameters.jafari);
      final date = DateTime.utc(2026, 8, 22);
      final current = engine.getTimesAsHours(
        date,
        33.3128,
        44.3615,
        3,
      );
      final next = engine.getTimesAsHours(
        date.add(const Duration(days: 1)),
        33.3128,
        44.3615,
        3,
      );
      final expected =
          current['sunset']! + ((next['fajr']! + 24) - current['sunset']!) / 2;

      expect(current['midnight'], closeTo(expected, 0.02));
      expect(current['midnight']!.isFinite, isTrue);
    });

    test(
        'invalid high-latitude values are omitted rather than converted to 00:00',
        () {
      final service = PrayerTimesService();
      final position = const PrayerLocation(
        latitude: 69.6492,
        longitude: 18.9553,
        source: PrayerLocationSource.selectedCity,
        displayName: 'Tromsø',
        timeZoneOffsetHours: 2,
      ).toPosition();
      final times = service.calculatePrayerTimes(
        position,
        date: DateTime.utc(2026, 6, 21),
        timeZoneOffsetHours: 2,
      );

      expect(times.values.every((value) => value.isUtc), isTrue);
      expect(
          times.values.every((value) => value.hour != 0 || value.minute != 0),
          isTrue);
    });
  });
}
