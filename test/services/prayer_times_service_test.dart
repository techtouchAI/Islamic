import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:aldhakereen/services/prayer_times_service.dart';
import 'package:adhan_dart/adhan_dart.dart';

void main() {
  group('PrayerTimesService - calculatePrayerTimes', () {
    late PrayerTimesService service;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      service = PrayerTimesService();
    });

    // Helper function to create a dummy Position
    Position createDummyPosition(double latitude, double longitude) {
      return Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }

    test('should return correct map of prayer times for a given position and date', () {
      // Mecca coordinates
      final position = createDummyPosition(21.4225, 39.8262);
      final date = DateTime(2023, 10, 15);

      final times = service.calculatePrayerTimes(position, date: date);

      expect(times, containsPair('fajr', isA<DateTime>()));
      expect(times, containsPair('sunrise', isA<DateTime>()));
      expect(times, containsPair('dhuhr', isA<DateTime>()));
      expect(times, containsPair('asr', isA<DateTime>()));
      expect(times, containsPair('maghrib', isA<DateTime>()));
      expect(times, containsPair('isha', isA<DateTime>()));
      expect(times, containsPair('midnight', isA<DateTime>()));

      // Check if dates are matching the requested date
      expect(times['dhuhr']!.year, 2023);
      expect(times['dhuhr']!.month, 10);
      expect(times['dhuhr']!.day, 15);
    });

    test('should return prayer times even if date is not provided (defaults to now)', () {
      final position = createDummyPosition(21.4225, 39.8262);

      final times = service.calculatePrayerTimes(position);

      final now = DateTime.now();
      expect(times['dhuhr']!.year, now.year);
      expect(times['dhuhr']!.month, now.month);
      expect(times['dhuhr']!.day, now.day);
    });

    test('should correctly calculate midnight as halfway between maghrib and next fajr based on service logic', () {
      final position = createDummyPosition(33.3152, 44.3661); // Baghdad
      final date = DateTime(2023, 1, 1);

      final times = service.calculatePrayerTimes(position, date: date);

      final midnight = times['midnight']!;

      // We know from the service implementation:
      // final nextFajr = pt.fajr.add(const Duration(days: 1)).toLocal();
      // It adds exactly 24 hours to the current day's fajr instead of calculating the actual next day's fajr
      final pt = PrayerTimes(
        coordinates: Coordinates(position.latitude, position.longitude),
        date: date,
        calculationParameters: service.shiaJafariParams,
        precision: true,
      );

      final maghrib = pt.maghrib.toLocal();
      final nextFajr = pt.fajr.add(const Duration(days: 1)).toLocal();
      final expectedDuration = nextFajr.difference(maghrib);
      final expectedMidnight = maghrib.add(Duration(seconds: (expectedDuration.inSeconds / 2).round()));

      expect(midnight.isAtSameMomentAs(expectedMidnight), isTrue);
    });

    test('should handle extreme latitudes gracefully', () {
      // Tromso, Norway - above Arctic circle
      final position = createDummyPosition(69.6492, 18.9553);
      final date = DateTime(2023, 6, 21); // Summer solstice

      final times = service.calculatePrayerTimes(position, date: date);

      expect(times.containsKey('fajr'), isTrue);
      expect(times.containsKey('dhuhr'), isTrue);
      expect(times.containsKey('maghrib'), isTrue);

      expect(times['fajr'], isA<DateTime>());
      expect(times['maghrib'], isA<DateTime>());
    });
  });
}
