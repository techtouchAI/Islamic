import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/iraq_provinces.dart';
import '../../services/prayer_times_service.dart';
import '../../services/prayer_alarm_service.dart';
import '../../models/prayer_location.dart';
import '../../models/prayer_schedule.dart';

class PrayerTimesSection extends StatefulWidget {
  const PrayerTimesSection({super.key});
  @override
  State<PrayerTimesSection> createState() => _PrayerTimesSectionState();
}

class _PrayerTimesSectionState extends State<PrayerTimesSection> {
  Map<String, DateTime>? _prayerTimes;
  PrayerSchedule? _prayerSchedule;
  PrayerLocation? _prayerLocation;
  bool _loading = true;
  final PrayerTimesService _prayerService = PrayerTimesService();
  final Map<String, bool> _enabledPrayers = {
    'fajr': true,
    'dhuhr': true,
    'asr': false,
    'maghrib': true,
    'isha': false,
  };
  final Map<String, bool> _fullScreenPrayers = {
    'fajr': false,
    'dhuhr': false,
    'asr': false,
    'maghrib': false,
    'isha': false,
  };
  bool _ignoreBatteryOptimizations = false;
  double _adhanVolume = 1.0;
  int _adhanPreAlert = 0;
  bool? _exactAlarmAvailable;
  bool? _fullScreenAvailable;

  final Map<String, int> _manualAdjustments = {
    'fajr': 0,
    'dhuhr': 0,
    'asr': 0,
    'maghrib': 0,
    'isha': 0,
  };
  String _selectedProvince = "بغداد";

  @override
  void initState() {
    super.initState();
    _initializePrayerTimes();
  }

  Future<void> _initializePrayerTimes() async {
    await _loadSettings();
    if (!mounted) return;
    await _refreshPermissionStates();
    if (!mounted) return;
    await _refreshPrayerTimes();
  }

  Future<void> _refreshPermissionStates() async {
    final exact = await PrayerAlarmService.checkExactAlarmPermission();
    final fullScreen = await PrayerAlarmService.checkFullScreenPermission();
    if (!mounted) return;
    setState(() {
      _exactAlarmAvailable = exact;
      _fullScreenAvailable = fullScreen;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabledPrayers['fajr'] = prefs.getBool('adhan_fajr') ??
          PrayerTimesService.isAdhanEnabledByDefault('fajr');
      _enabledPrayers['dhuhr'] = prefs.getBool('adhan_dhuhr') ??
          PrayerTimesService.isAdhanEnabledByDefault('dhuhr');
      _enabledPrayers['asr'] = prefs.getBool('adhan_asr') ??
          PrayerTimesService.isAdhanEnabledByDefault('asr');
      _enabledPrayers['maghrib'] = prefs.getBool('adhan_maghrib') ??
          PrayerTimesService.isAdhanEnabledByDefault('maghrib');
      _enabledPrayers['isha'] = prefs.getBool('adhan_isha') ??
          PrayerTimesService.isAdhanEnabledByDefault('isha');
      _fullScreenPrayers['fajr'] = prefs.getBool('fullscreen_fajr') ?? false;
      _fullScreenPrayers['dhuhr'] = prefs.getBool('fullscreen_dhuhr') ?? false;
      _fullScreenPrayers['asr'] = prefs.getBool('fullscreen_asr') ?? false;
      _fullScreenPrayers['maghrib'] =
          prefs.getBool('fullscreen_maghrib') ?? false;
      _fullScreenPrayers['isha'] = prefs.getBool('fullscreen_isha') ?? false;
      _ignoreBatteryOptimizations =
          prefs.getBool('ignore_battery_optimizations') ?? false;
      _adhanVolume = prefs.getDouble('adhan_volume') ?? 1.0;
      _adhanPreAlert = prefs.getInt('adhan_pre_alert') ?? 0;
      _manualAdjustments['fajr'] = prefs.getInt('adj_fajr') ?? 0;
      _manualAdjustments['dhuhr'] = prefs.getInt('adj_dhuhr') ?? 0;
      _manualAdjustments['asr'] = prefs.getInt('adj_asr') ?? 0;
      _manualAdjustments['maghrib'] = prefs.getInt('adj_maghrib') ?? 0;
      _manualAdjustments['isha'] = prefs.getInt('adj_isha') ?? 0;
      _selectedProvince = prefs.getString('prayer_city') ?? "بغداد";

      // The canonical location record is resolved by PrayerTimesService after
      // all settings have loaded. No separate GPS cache is read here.
    });
  }

  Future<void> _refreshPrayerTimes() async {
    if (mounted) setState(() => _loading = true);
    try {
      final schedule = await _prayerService.loadTodaySchedule();
      if (schedule == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (!mounted) return;
      setState(() {
        _prayerLocation = schedule.location;
        _prayerSchedule = schedule;
        _prayerTimes = schedule.availableUtcTimes;
        _loading = false;
      });

      await _prayerService.scheduleAdhanNotifications(
        schedule.location,
        _enabledPrayers,
        _manualAdjustments,
      );
    } catch (error, stackTrace) {
      debugPrint('Prayer times error: $error\n$stackTrace');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useGPS() async {
    if (mounted) setState(() => _loading = true);
    final location = await _prayerService.resolveLocation(
      selectedCity: PrayerTimesService.gpsLocationName,
      refreshGps: true,
    );
    if (location == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر تحديد الموقع الحالي. تحقق من GPS والصلاحية.')),
      );
      setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() {
      _prayerLocation = location;
      _selectedProvince = PrayerTimesService.gpsLocationName;
    });
    await _refreshPrayerTimes();
    if (!mounted) return;
    if (!location.isGps) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('تعذر تحديث GPS؛ تم استخدام ${location.displayName}.')),
      );
    }
  }

  Future<PrayerLocation?> _resolveLocationForAction() async {
    final location = await _prayerService.resolveLocation(
      selectedCity: _selectedProvince,
      refreshGps: false,
    );
    if (location != null && mounted) {
      setState(() {
        _prayerLocation = location;
      });
    }
    return location;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Text(
          "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ",
          style: TextStyle(
            fontFamily: 'me_quran',
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on),
                    const SizedBox(width: 10),
                    const Text(
                      'المحافظة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _selectedProvince,
                      underline: const SizedBox(),
                      onChanged: (v) async {
                        if (v != null) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('prayer_city', v);
                          setState(() {
                            _selectedProvince = v;
                            _prayerLocation = null;
                            _loading = true;
                          });
                          await _refreshPrayerTimes();
                        }
                      },
                      items: [
                        ...iraqProvinces.keys.map(
                          (p) => DropdownMenuItem(value: p, child: Text(p)),
                        ),
                        if (_selectedProvince == "الموقع الحالي (GPS)")
                          const DropdownMenuItem(
                            value: "الموقع الحالي (GPS)",
                            child: Text("الموقع الحالي (GPS)"),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_prayerLocation != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'مصدر الحساب: ${_prayerLocation!.displayName}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                const Divider(),
                TextButton.icon(
                  onPressed: _useGPS,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _prayerLocation == null
                        ? 'استخدام الموقع الحالي (GPS)'
                        : _prayerLocation!.isGps
                            ? 'GPS حي (${_prayerLocation!.accuracyMeters!.round()}م)'
                            : 'استخدام ${_prayerLocation!.displayName}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPrayerCard('الفجر', _prayerSchedule?['fajr'], 'fajr'),
          _buildPrayerCard('الظهر', _prayerSchedule?['dhuhr'], 'dhuhr'),
          _buildPrayerCard('العصر', _prayerSchedule?['asr'], 'asr'),
          _buildPrayerCard('المغرب', _prayerSchedule?['maghrib'], 'maghrib'),
          _buildPrayerCard('العشاء', _prayerSchedule?['isha'], 'isha'),
          const SizedBox(height: 30),
          const Divider(),
          const Text(
            'إعدادات الأذان والتنبيهات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          ..._enabledPrayers.keys.map(
            (k) => Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'تفعيل أذان ${{
                        'fajr': 'الفجر',
                        'dhuhr': 'الظهر',
                        'asr': 'العصر',
                        'maghrib': 'المغرب',
                        'isha': 'العشاء'
                      }[k]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _enabledPrayers[k] ?? true,
                    onChanged: (v) async {
                      setState(() => _enabledPrayers[k] = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('adhan_$k', v);

                      final location = await _resolveLocationForAction();
                      if (location != null) {
                        await _prayerService.rescheduleSinglePrayerForLocation(
                            k, location);
                      }
                    },
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              setState(() => _fullScreenPrayers[k] = false);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('fullscreen_$k', false);

                              final location =
                                  await _resolveLocationForAction();
                              if (location != null) {
                                await _prayerService
                                    .rescheduleSinglePrayerForLocation(
                                        k, location);
                              }
                            },
                            child: Card(
                              color: (_fullScreenPrayers[k] ?? false)
                                  ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                  : Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                              elevation:
                                  (_fullScreenPrayers[k] ?? false) ? 0 : 2,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.notifications,
                                        color: (_fullScreenPrayers[k] ?? false)
                                            ? Colors.grey
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary),
                                    const SizedBox(height: 5),
                                    Text('إشعار',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                (_fullScreenPrayers[k] ?? false)
                                                    ? Colors.grey
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .primary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              setState(() => _fullScreenPrayers[k] = true);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('fullscreen_$k', true);

                              final location =
                                  await _resolveLocationForAction();
                              if (location != null) {
                                await _prayerService
                                    .rescheduleSinglePrayerForLocation(
                                        k, location);
                              }
                            },
                            child: Card(
                              color: (_fullScreenPrayers[k] ?? false)
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              elevation:
                                  (_fullScreenPrayers[k] ?? false) ? 2 : 0,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.fullscreen,
                                        color: (_fullScreenPrayers[k] ?? false)
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.grey),
                                    const SizedBox(height: 5),
                                    Text('شاشة كاملة',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                (_fullScreenPrayers[k] ?? false)
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                    : Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('مستوى الصوت',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Slider(
                          value: _adhanVolume,
                          onChanged: (v) async {
                            setState(() => _adhanVolume = v);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setDouble('adhan_volume', v);
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('تنبيه قبل الأذان',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle:
                        const Text('دقائق', style: TextStyle(fontSize: 12)),
                    trailing: DropdownButton<int>(
                      value: _adhanPreAlert,
                      items: [0, 5, 10, 15, 20, 30].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value == 0 ? 'معطل' : '$value'),
                        );
                      }).toList(),
                      onChanged: (v) async {
                        if (v != null) {
                          setState(() => _adhanPreAlert = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('adhan_pre_alert', v);
                          await _refreshPrayerTimes(); // Reschedule with pre alerts
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('المنبه الدقيق',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _exactAlarmAvailable == true
                          ? 'مفعّل: يمكن تشغيل الأذان في الموعد بدقة أعلى'
                          : 'غير مفعّل: قد يتأخر التنبيه بسبب قيود النظام',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: _exactAlarmAvailable == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: () async {
                              await PrayerAlarmService.openExactAlarmSettings();
                              await _refreshPermissionStates();
                              await _refreshPrayerTimes();
                            },
                            child: const Text('تفعيل'),
                          ),
                  ),
                  ListTile(
                    title: const Text('الشاشة الكاملة',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _fullScreenAvailable == true
                          ? 'مسموح به من النظام'
                          : 'قد يظهر التنبيه كرأس إشعار بدل فتح الشاشة',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      _fullScreenAvailable == true
                          ? Icons.check_circle
                          : Icons.info_outline,
                      color: _fullScreenAvailable == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('قناة الإشعارات',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('إعدادات النظام للإشعارات',
                        style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.settings),
                    onTap: () async {
                      // Launch native Android notification settings for the app channel
                      await const MethodChannel('com.techtouchai.islamic/adhan')
                          .invokeMethod('openNotificationSettings');
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('تخطي وضع توفير الطاقة (Doze Mode)',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text('مطلوب لضمان عمل الأذان في وقته بدقة',
                        style: TextStyle(fontSize: 12)),
                    value: _ignoreBatteryOptimizations,
                    onChanged: (v) async {
                      setState(() => _ignoreBatteryOptimizations = v);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('ignore_battery_optimizations', v);
                      if (v) {
                        if (await Permission
                            .ignoreBatteryOptimizations.isDenied) {
                          await Permission.ignoreBatteryOptimizations.request();
                        }
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(String label, PrayerTimeValue? prayer, String key) {
    final localTime = prayer?.localCivilTime;
    if (localTime == null) return const SizedBox();
    final adjTime = localTime;
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: const Text(
          'اضغط لتعديل الوقت يدوياً (دقائق)',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
        trailing: Text(
          intl.DateFormat('hh:mm a').format(adjTime),
          style: TextStyle(
            fontSize: 22,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(adjTime),
          );
          if (picked != null) {
            final pickedDateTimeLocal = DateTime.utc(
              localTime.year,
              localTime.month,
              localTime.day,
              picked.hour,
              picked.minute,
            );
            final diff = pickedDateTimeLocal.difference(localTime).inMinutes;

            // التحقق من الإزاحة الجديدة لضمان عدم التداخل
            final validatedDiff =
                _prayerService.validateOffset(key, diff, _prayerTimes!);

            if (!mounted) return;
            setState(() {
              _manualAdjustments[key] = validatedDiff;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('adj_$key', validatedDiff);
            await _refreshPrayerTimes();

            if (validatedDiff != diff) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'تم ضبط الوقت لأقرب قيمة مسموح بها لمنع التداخل مع الصلاة المجاورة')),
              );
            }
          }
        },
      ),
    );
  }
}
