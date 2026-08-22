import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/data_manager.dart';
import '../data/iraq_provinces.dart';
import '../models/prayer_location.dart';
import '../models/prayer_schedule.dart';
import '../utils/pray_times.dart';
import '../utils/prayer_time_zone.dart';
import 'prayer_alarm_service.dart';

/// The single source of truth for prayer location, calculation and scheduling.
class PrayerTimesService with WidgetsBindingObserver {
  static final PrayerTimesService _instance = PrayerTimesService._internal();
  factory PrayerTimesService() => _instance;

  static const String gpsLocationName = 'الموقع الحالي (GPS)';
  static const String defaultCityName = 'بغداد';
  static const double defaultLatitude = 33.3128;
  static const double defaultLongitude = 44.3615;
  static const double maxAcceptedAccuracyMeters = 1000;
  static const Duration maxCachedLocationAge = Duration(days: 7);

  static const String _sourceKey = 'prayer_location_source';
  static const String _cityKey = 'prayer_city';
  static const String _latitudeKey = 'prayer_location_lat';
  static const String _longitudeKey = 'prayer_location_lon';
  static const String _accuracyKey = 'prayer_location_accuracy';
  static const String _capturedAtKey = 'prayer_location_captured_at';
  static const String _lastGpsLatitudeKey = 'prayer_last_gps_lat';
  static const String _lastGpsLongitudeKey = 'prayer_last_gps_lon';
  static const String _lastGpsAccuracyKey = 'prayer_last_gps_accuracy';
  static const String _lastGpsCapturedAtKey = 'prayer_last_gps_captured_at';
  static const String _lastGpsTimezoneKey = 'prayer_last_gps_timezone';
  static const String _manualSchedulePrefix = 'manual_schedule_';

  late PrayerTimesEngine _engine;

  PrayerTimesService._internal() {
    _engine = PrayTimes(PrayerCalculationParameters.jafari);
    _initLifecycleObserver();
  }

  void _initLifecycleObserver() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      forceReschedule().catchError((error) {
        debugPrint('Prayer reschedule on resume failed: $error');
      });
    }
  }

  void setEngine(PrayerTimesEngine engine) {
    _engine = engine;
  }

  /// Resolves the location selected by the user and persists one canonical record.
  /// GPS is refreshed only when the user selected GPS; a failed refresh is exposed
  /// as cachedLocation rather than being mislabeled as live GPS.
  Future<PrayerLocation?> resolveLocation({
    String? selectedCity,
    bool refreshGps = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyLocationKeys(prefs);

    final storedCity = prefs.getString(_cityKey) ?? defaultCityName;
    final city = selectedCity ?? storedCity;
    if (city != gpsLocationName) {
      final location = _locationForCity(city);
      await _persistLocationSelection(prefs, location, city: city);
      return location;
    }

    if (refreshGps) {
      final liveGps = await _readLiveGpsLocation();
      if (liveGps != null) {
        await _persistLocationSelection(prefs, liveGps, city: gpsLocationName);
        return liveGps;
      }
    }

    final cached = _readCachedLocation(prefs);
    if (cached != null) {
      final cachedLocation = cached.copyWith(
        source: PrayerLocationSource.cachedLocation,
        displayName: 'آخر موقع GPS محفوظ',
      );
      await _persistLocationSelection(prefs, cachedLocation,
          city: gpsLocationName);
      return cachedLocation;
    }

    // Default is explicit and visible, and is used only if no city or valid
    // location record is available at all.
    final defaultLocation = _locationForCity(defaultCityName).copyWith(
      source: PrayerLocationSource.defaultLocation,
      displayName: 'الموقع الافتراضي: $defaultCityName',
    );
    await _persistLocationSelection(prefs, defaultLocation,
        city: gpsLocationName);
    return defaultLocation;
  }

  /// Legacy API retained for callers that only need coordinates.
  /// It no longer claims that a fallback coordinate is live GPS.
  Future<Position?> getCurrentLocation() async {
    final location = await resolveLocation(refreshGps: true);
    return location?.toPosition();
  }

  Future<PrayerLocation?> _readLiveGpsLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('Location services are disabled; live GPS unavailable.');
        return null;
      }

      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }
      if (!status.isGranted) {
        debugPrint('Location permission is not granted: $status');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!position.accuracy.isFinite ||
          position.accuracy <= 0 ||
          position.accuracy > maxAcceptedAccuracyMeters) {
        debugPrint(
          'Live GPS accuracy is outside the accepted range: ${position.accuracy}m',
        );
        return null;
      }

      return PrayerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        source: PrayerLocationSource.gps,
        displayName: 'الموقع الحالي عبر GPS',
        accuracyMeters: position.accuracy,
        capturedAt: position.timestamp,
        timeZoneOffsetHours: PrayerTimeZonePolicy.forGpsDevice(DateTime.now()),
      );
    } catch (error) {
      debugPrint('Live GPS lookup failed: $error');
      return null;
    }
  }

  PrayerLocation? _readCachedLocation(SharedPreferences prefs) {
    final latitude = prefs.getDouble(_lastGpsLatitudeKey);
    final longitude = prefs.getDouble(_lastGpsLongitudeKey);
    if (latitude == null || longitude == null) return null;
    if (!latitude.isFinite || !longitude.isFinite) return null;
    if (latitude.abs() > 90 || longitude.abs() > 180) return null;

    final capturedAtRaw = prefs.getString(_lastGpsCapturedAtKey);
    final capturedAt = capturedAtRaw == null
        ? null
        : DateTime.tryParse(capturedAtRaw)?.toLocal();
    if (capturedAt == null ||
        DateTime.now().difference(capturedAt).abs() > maxCachedLocationAge) {
      debugPrint('Cached GPS location is missing or stale.');
      return null;
    }

    return PrayerLocation(
      latitude: latitude,
      longitude: longitude,
      source: PrayerLocationSource.cachedLocation,
      displayName: 'آخر موقع GPS محفوظ',
      accuracyMeters: prefs.getDouble(_lastGpsAccuracyKey),
      capturedAt: capturedAt,
      timeZoneOffsetHours: prefs.getDouble(_lastGpsTimezoneKey) ??
          PrayerTimeZonePolicy.forGpsDevice(DateTime.now()),
    );
  }

  PrayerLocation _locationForCity(String city) {
    final coordinates = iraqProvinces[city] ?? iraqProvinces[defaultCityName]!;
    final isKnownCity = iraqProvinces.containsKey(city);
    return PrayerLocation(
      latitude: coordinates[0],
      longitude: coordinates[1],
      source: isKnownCity
          ? PrayerLocationSource.selectedCity
          : PrayerLocationSource.defaultLocation,
      displayName: isKnownCity ? city : 'الموقع الافتراضي: $defaultCityName',
      timeZoneOffsetHours: PrayerTimeZonePolicy.forSelectedIraqiCity(),
    );
  }

  Future<void> _persistLocationSelection(
    SharedPreferences prefs,
    PrayerLocation location, {
    required String city,
  }) async {
    await prefs.setString(_sourceKey, location.source.storageValue);
    await prefs.setString(_cityKey, city);
    await prefs.setDouble(_latitudeKey, location.latitude);
    await prefs.setDouble(_longitudeKey, location.longitude);
    await prefs.setDouble(
      'prayer_location_timezone',
      location.timeZoneOffsetHours,
    );
    if (location.isGps) {
      await prefs.setDouble(_lastGpsLatitudeKey, location.latitude);
      await prefs.setDouble(_lastGpsLongitudeKey, location.longitude);
      await prefs.setDouble(_lastGpsTimezoneKey, location.timeZoneOffsetHours);
      if (location.accuracyMeters != null) {
        await prefs.setDouble(_lastGpsAccuracyKey, location.accuracyMeters!);
      }
      if (location.capturedAt != null) {
        await prefs.setString(
          _lastGpsCapturedAtKey,
          location.capturedAt!.toIso8601String(),
        );
      }
    }
    if (location.accuracyMeters != null) {
      await prefs.setDouble(_accuracyKey, location.accuracyMeters!);
    }
    if (location.capturedAt != null) {
      await prefs.setString(
        _capturedAtKey,
        location.capturedAt!.toIso8601String(),
      );
    }
  }

  Future<void> _migrateLegacyLocationKeys(SharedPreferences prefs) async {
    if (prefs.containsKey(_latitudeKey) && prefs.containsKey(_longitudeKey)) {
      return;
    }

    final legacyGpsLat = prefs.getDouble('gps_lat');
    final legacyGpsLon = prefs.getDouble('gps_lon');
    final legacyCachedLat = prefs.getDouble('cached_lat');
    final legacyCachedLon = prefs.getDouble('cached_lon');
    final lat = legacyGpsLat ?? legacyCachedLat;
    final lon = legacyGpsLon ?? legacyCachedLon;
    if (lat == null || lon == null) return;

    await prefs.setDouble(_latitudeKey, lat);
    await prefs.setDouble(_longitudeKey, lon);
    await prefs.setDouble(_lastGpsLatitudeKey, lat);
    await prefs.setDouble(_lastGpsLongitudeKey, lon);
    await prefs.setString(
      _sourceKey,
      legacyGpsLat != null
          ? PrayerLocationSource.gps.storageValue
          : PrayerLocationSource.cachedLocation.storageValue,
    );
    await prefs.setString(
      _capturedAtKey,
      DateTime.now().toIso8601String(),
    );
    await prefs.setString(
      _lastGpsCapturedAtKey,
      DateTime.now().toIso8601String(),
    );
    await prefs.setDouble(
      'prayer_location_timezone',
      PrayerTimeZonePolicy.forGpsDevice(DateTime.now()),
    );
  }

  /// Calculates raw prayer times and returns only finite, valid values.
  /// The legacy return type remains available for existing consumers.
  Map<String, DateTime> calculatePrayerTimes(
    Position position, {
    DateTime? date,
    double timeZoneOffsetHours = 0,
  }) {
    final raw = _engine.getTimesAsHours(
      date ?? DateTime.now(),
      position.latitude,
      position.longitude,
      timeZoneOffsetHours,
    );
    final result = <String, DateTime>{};
    for (final entry in raw.entries) {
      if (!entry.value.isFinite) continue;
      final localCivil =
          _hoursToCivilDateTime(date ?? DateTime.now(), entry.value);
      result[entry.key] = PrayerTimeZonePolicy.localCivilToUtc(
        localCivil,
        timeZoneOffsetHours,
      );
    }
    return result;
  }

  PrayerSchedule buildSchedule(
    PrayerLocation location, {
    DateTime? date,
    Map<String, int> offsets = const <String, int>{},
    Map<String, String>? manualSchedule,
  }) {
    final scheduleDate = _dateOnly(
      date ??
          PrayerTimeZonePolicy.utcToLocalCivil(
            DateTime.now().toUtc(),
            location.timeZoneOffsetHours,
          ),
    );
    final raw = _engine.getTimesAsHours(
      scheduleDate,
      location.latitude,
      location.longitude,
      location.timeZoneOffsetHours,
    );
    final values = <String, PrayerTimeValue>{};

    for (final entry in raw.entries) {
      final key = entry.key;
      final rawHours = entry.value;
      if (!rawHours.isFinite) {
        values[key] = PrayerTimeValue(
          key: key,
          utcTime: null,
          localCivilTime: null,
        );
        continue;
      }

      var localCivil = _hoursToCivilDateTime(scheduleDate, rawHours);
      final manual = manualSchedule?[key];
      if (manual != null) {
        final parsed = _parseManualTime(scheduleDate, manual);
        if (parsed != null) localCivil = parsed;
      }
      localCivil = localCivil.add(Duration(minutes: offsets[key] ?? 0));
      final utc = PrayerTimeZonePolicy.localCivilToUtc(
        localCivil,
        location.timeZoneOffsetHours,
      );
      values[key] = PrayerTimeValue(
        key: key,
        utcTime: utc,
        localCivilTime: localCivil,
      );
    }

    return PrayerSchedule(
      date: scheduleDate,
      location: location,
      prayers: values,
    );
  }

  DateTime _hoursToCivilDateTime(DateTime date, double hours) {
    final base = DateTime.utc(date.year, date.month, date.day);
    final totalMinutes = (hours * 60).round();
    return base.add(Duration(minutes: totalMinutes));
  }

  DateTime? _parseManualTime(DateTime date, String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime.utc(date.year, date.month, date.day, hour, minute);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  Future<PrayerSchedule?> loadTodaySchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityKey) ?? defaultCityName;
    final location = await resolveLocation(
      selectedCity: city,
      refreshGps: city == gpsLocationName,
    );
    if (location == null) return null;

    final nowLocal = PrayerTimeZonePolicy.utcToLocalCivil(
      DateTime.now().toUtc(),
      location.timeZoneOffsetHours,
    );
    final today = _dateOnly(nowLocal);
    final offsets = <String, int>{
      for (final key in _adhanPrayerKeys) key: prefs.getInt('adj_$key') ?? 0,
    };
    return buildSchedule(
      location,
      date: today,
      offsets: offsets,
      manualSchedule: await _getManualScheduleForDate(today),
    );
  }

  String dateKey(DateTime date) {
    final value = _dateOnly(date);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> saveManualScheduleForDate(
    DateTime date,
    Map<String, String> schedule,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_manualSchedulePrefix${dateKey(date)}',
      jsonEncode(schedule),
    );
  }

  Future<Map<String, String>?> _getManualScheduleForDate(DateTime date) async {
    final db = DataManager.getDB();
    final settings = db?['settings'];
    final adhan = settings is Map ? settings['adhan'] : null;
    final schedules = adhan is Map ? adhan['manual_schedules'] : null;

    if (schedules is List) {
      final targetDate = dateKey(date);
      for (final item in schedules) {
        if (item is! Map || item['date']?.toString() != targetDate) continue;
        final result = <String, String>{};
        for (final key in _adhanPrayerKeys) {
          final value = item[key]?.toString();
          if (value != null && value.contains(':')) result[key] = value;
        }
        if (result.isNotEmpty) {
          await saveManualScheduleForDate(date, result);
          return result;
        }
      }
      await clearManualScheduleForDate(date);
      return null;
    }

    // At boot the Flutter content database may not be loaded yet; use the
    // explicitly persisted schedule until the content source is available.
    return _readManualScheduleForDate(date);
  }

  Future<void> clearManualScheduleForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_manualSchedulePrefix${dateKey(date)}');
  }

  Future<Map<String, String>?> _readManualScheduleForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_manualSchedulePrefix${dateKey(date)}');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return decoded.map<String, String>(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (error) {
      debugPrint('Invalid saved manual schedule: $error');
      return null;
    }
  }

  /// Validates a manual adjustment while preserving the existing free-adjustment behavior.
  int validateOffset(
    String prayerKey,
    int requestedOffsetMinutes,
    Map<String, DateTime> baseTimes,
  ) {
    if (!baseTimes.containsKey(prayerKey)) return requestedOffsetMinutes;
    return requestedOffsetMinutes.clamp(-24 * 60, 24 * 60).toInt();
  }

  static const List<String> _adhanPrayerKeys = <String>[
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  int _getPrayerId(String key) {
    switch (key) {
      case 'fajr':
        return 1;
      case 'dhuhr':
        return 2;
      case 'asr':
        return 3;
      case 'maghrib':
        return 4;
      case 'isha':
        return 5;
      default:
        return 0;
    }
  }

  String _getPrayerNameAr(String key) {
    switch (key) {
      case 'fajr':
        return 'الفجر';
      case 'dhuhr':
        return 'الظهر';
      case 'asr':
        return 'العصر';
      case 'maghrib':
        return 'المغرب';
      case 'isha':
        return 'العشاء';
      default:
        return key;
    }
  }

  Future<void> forceReschedule() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString(_cityKey) ?? defaultCityName;
    final location = await resolveLocation(
      selectedCity: city,
      refreshGps: city == gpsLocationName,
    );
    if (location == null) return;

    final enabled = <String, bool>{
      for (final key in _adhanPrayerKeys)
        key: prefs.getBool('adhan_$key') ?? true,
    };
    final offsets = <String, int>{
      for (final key in _adhanPrayerKeys) key: prefs.getInt('adj_$key') ?? 0,
    };
    await scheduleAdhanNotifications(location, enabled, offsets);
    await prefs.setString('last_bg_sync', DateTime.now().toIso8601String());
  }

  Future<void> scheduleAdhanNotifications(
    PrayerLocation location,
    Map<String, bool> enabledPrayers,
    Map<String, int> offsets,
  ) async {
    final notificationStatus = await Permission.notification.status;
    if (notificationStatus.isDenied) {
      await Permission.notification.request();
    }

    final nowLocal = PrayerTimeZonePolicy.utcToLocalCivil(
      DateTime.now().toUtc(),
      location.timeZoneOffsetHours,
    );
    final today = _dateOnly(nowLocal);

    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = today.add(Duration(days: dayIndex));
      final manualSchedule = await _getManualScheduleForDate(date);
      final schedule = buildSchedule(
        location,
        date: date,
        offsets: offsets,
        manualSchedule: manualSchedule,
      );

      for (final key in _adhanPrayerKeys) {
        final id = dayIndex * 10 + _getPrayerId(key);
        await PrayerAlarmService.cancelPrayer(id);
        final prayer = schedule[key];
        final time = prayer?.utcTime;
        if (prayer == null || time == null || !(enabledPrayers[key] ?? true)) {
          continue;
        }
        await _scheduleSingleNotification(
          id,
          _getPrayerNameAr(key),
          prayer,
          location,
          key,
        );
      }
    }
  }

  Future<void> rescheduleSinglePrayer(
    String prayerKey,
    Position position,
  ) async {
    final location = PrayerLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      source: PrayerLocationSource.selectedCity,
      displayName: 'الموقع المحدد',
      timeZoneOffsetHours: PrayerTimeZonePolicy.forGpsDevice(DateTime.now()),
      accuracyMeters: position.accuracy,
      capturedAt: position.timestamp,
    );
    await rescheduleSinglePrayerForLocation(prayerKey, location);
  }

  Future<void> rescheduleSinglePrayerForLocation(
    String prayerKey,
    PrayerLocation location,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final offset = prefs.getInt('adj_$prayerKey') ?? 0;
    final enabled = prefs.getBool('adhan_$prayerKey') ?? true;
    final nowLocal = PrayerTimeZonePolicy.utcToLocalCivil(
      DateTime.now().toUtc(),
      location.timeZoneOffsetHours,
    );
    final today = _dateOnly(nowLocal);

    for (var dayIndex = 0; dayIndex < 7; dayIndex++) {
      final id = dayIndex * 10 + _getPrayerId(prayerKey);
      await PrayerAlarmService.cancelPrayer(id);
      if (!enabled) continue;

      final date = today.add(Duration(days: dayIndex));
      final schedule = buildSchedule(
        location,
        date: date,
        offsets: <String, int>{prayerKey: offset},
        manualSchedule: await _getManualScheduleForDate(date),
      );
      final prayer = schedule[prayerKey];
      final time = prayer?.utcTime;
      if (prayer == null || time == null) continue;
      await _scheduleSingleNotification(
        id,
        _getPrayerNameAr(prayerKey),
        prayer,
        location,
        prayerKey,
      );
    }
  }

  Future<void> _scheduleSingleNotification(
    int id,
    String name,
    PrayerTimeValue prayer,
    PrayerLocation location,
    String key,
  ) async {
    final time = prayer.utcTime;
    final localCivilTime = prayer.localCivilTime;
    if (time == null ||
        localCivilTime == null ||
        !time.isUtc ||
        !time.isAfter(DateTime.now().toUtc())) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await PrayerAlarmService.schedulePrayer(
      id,
      time,
      name,
      localCivilTime: localCivilTime,
      timezoneOffsetMinutes: (location.timeZoneOffsetHours * 60).round(),
      timezoneUsesDevice: location.source == PrayerLocationSource.gps ||
          location.source == PrayerLocationSource.cachedLocation,
      fullScreen: prefs.getBool('fullscreen_$key') ?? false,
      volume: prefs.getDouble('adhan_volume') ?? 1.0,
      preAlertMinutes: prefs.getInt('adhan_pre_alert') ?? 0,
    );
  }
}
