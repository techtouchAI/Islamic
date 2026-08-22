import 'package:geolocator/geolocator.dart';

/// Origin of the coordinates used by the prayer-time pipeline.
enum PrayerLocationSource {
  gps,
  selectedCity,
  cachedLocation,
  defaultLocation,
}

extension PrayerLocationSourceLabel on PrayerLocationSource {
  String get storageValue {
    switch (this) {
      case PrayerLocationSource.gps:
        return 'gps';
      case PrayerLocationSource.selectedCity:
        return 'selected_city';
      case PrayerLocationSource.cachedLocation:
        return 'cached_location';
      case PrayerLocationSource.defaultLocation:
        return 'default_location';
    }
  }

  String get arabicLabel {
    switch (this) {
      case PrayerLocationSource.gps:
        return 'الموقع الحالي عبر GPS';
      case PrayerLocationSource.selectedCity:
        return 'المدينة المختارة';
      case PrayerLocationSource.cachedLocation:
        return 'آخر موقع محفوظ';
      case PrayerLocationSource.defaultLocation:
        return 'الموقع الافتراضي';
    }
  }

  static PrayerLocationSource fromStorage(String? value) {
    switch (value) {
      case 'gps':
        return PrayerLocationSource.gps;
      case 'cached_location':
        return PrayerLocationSource.cachedLocation;
      case 'default_location':
        return PrayerLocationSource.defaultLocation;
      case 'selected_city':
      default:
        return PrayerLocationSource.selectedCity;
    }
  }
}

class PrayerLocation {
  final double latitude;
  final double longitude;
  final PrayerLocationSource source;
  final String displayName;
  final double? accuracyMeters;
  final DateTime? capturedAt;
  final double timeZoneOffsetHours;

  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.displayName,
    required this.timeZoneOffsetHours,
    this.accuracyMeters,
    this.capturedAt,
  });

  bool get isGps => source == PrayerLocationSource.gps;

  Position toPosition() {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: capturedAt ?? DateTime.now(),
      accuracy: accuracyMeters ?? 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  PrayerLocation copyWith({
    PrayerLocationSource? source,
    String? displayName,
    double? accuracyMeters,
    DateTime? capturedAt,
    double? timeZoneOffsetHours,
  }) {
    return PrayerLocation(
      latitude: latitude,
      longitude: longitude,
      source: source ?? this.source,
      displayName: displayName ?? this.displayName,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      capturedAt: capturedAt ?? this.capturedAt,
      timeZoneOffsetHours: timeZoneOffsetHours ?? this.timeZoneOffsetHours,
    );
  }
}
