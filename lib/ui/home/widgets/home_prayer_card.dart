import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../data/repositories/calendar_repository.dart';
import '../../../models/prayer_schedule.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/next_prayer.dart';
import '../../../utils/string_extensions.dart';
import '../home_prayer_controller.dart';

class HomePrayerCard extends StatefulWidget {
  const HomePrayerCard({
    super.key,
    required this.hijriAdjustment,
    this.onTap,
    this.controller,
  });

  final int hijriAdjustment;
  final VoidCallback? onTap;
  final HomePrayerController? controller;

  @override
  State<HomePrayerCard> createState() => _HomePrayerCardState();
}

class _HomePrayerCardState extends State<HomePrayerCard>
    with WidgetsBindingObserver {
  late final HomePrayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? HomePrayerController();
    WidgetsBinding.instance.addObserver(this);
    _controller.start();
    _controller.refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.start();
      _controller.refresh();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.pause();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final upcoming = _controller.upcoming(widget.hijriAdjustment);
          final hijri = CalendarRepository.getTodayHijri(
            _controller.localNow,
            widget.hijriAdjustment,
          );
          final date = '${hijri.day} ${hijri.monthName} ${hijri.year} هـ'
              .toEasternArabic();
          final remaining = upcoming?.utcTime.difference(_controller.nowUtc);
          final title = upcoming == null
              ? 'أوقات الصلاة'
              : upcoming.key == 'imsak'
                  ? 'الإمساك'
                  : 'صلاة ${prayerDisplayNameAr(upcoming.key)}';
          return Material(
            key: const ValueKey('home-prayer-card'),
            color: AppPalette.forest,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [AppPalette.forestLight, AppPalette.forest],
                  ),
                ),
                child: Stack(
                  children: [
                    const PositionedDirectional(
                      start: -24,
                      top: 45,
                      child: ExcludeSemantics(
                        child: Icon(Icons.mosque_outlined,
                            size: 170, color: Color(0x0FFFFFFF)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.nightlight_round,
                                  size: 22, color: AppPalette.gold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(date,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _controller.today?.location.displayName ??
                                'مواقيت الصلاة بحسب الموقع المختار',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppPalette.gold,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700)),
                          if (_controller.loading)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppPalette.gold,
                                  semanticsLabel: 'جارٍ تحميل مواقيت الصلاة',
                                ),
                              ),
                            )
                          else if (remaining != null) ...[
                            Semantics(
                              label: 'الوقت المتبقي ${_countdown(remaining)}',
                              child: ExcludeSemantics(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _countdown(remaining),
                                    key: const ValueKey('prayer-countdown'),
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              upcoming!.key == 'imsak'
                                  ? 'المتبقي للإمساك'
                                  : 'المتبقي للأذان',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ] else if (!_controller.failed)
                            const Text('لا توجد مواقيت متاحة حالياً',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white)),
                          if (_controller.failed)
                            TextButton.icon(
                              onPressed: _controller.refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                  'تعذّر تحديث المواقيت · إعادة المحاولة'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white),
                            ),
                          const SizedBox(height: 16),
                          PrayerTimesStrip(
                            schedule: _controller.today,
                            nextKey: upcoming != null &&
                                    _controller.today?[upcoming.key]?.utcTime ==
                                        upcoming.utcTime
                                ? upcoming.key
                                : null,
                          ),
                          const SizedBox(height: 8),
                          const Text('عرض المواقيت وإعدادات الأذان  ‹',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  String _countdown(Duration value) {
    final seconds = value.inSeconds.clamp(0, 172800);
    String part(int n) => n.toString().padLeft(2, '0');
    return '${part(seconds ~/ 3600)}:${part(seconds ~/ 60 % 60)}:${part(seconds % 60)}'
        .toEasternArabic();
  }
}

/// Five equal-width cells in RTL order. At accessibility text sizes the strip
/// wraps instead of shrinking Arabic labels or overflowing a small phone.
class PrayerTimesStrip extends StatelessWidget {
  const PrayerTimesStrip({super.key, this.schedule, this.nextKey});
  final PrayerSchedule? schedule;
  final String? nextKey;

  static const keys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const icons = [
    Icons.wb_twilight,
    Icons.wb_sunny_outlined,
    Icons.light_mode_outlined,
    Icons.nights_stay_outlined,
    Icons.bedtime_outlined,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
          final columns =
              (constraints.maxWidth / (48 * scale)).floor().clamp(1, 5);
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPalette.gold.withValues(alpha: .2)),
            ),
            child: Wrap(
              children: List.generate(keys.length, (i) {
                final key = keys[i];
                final value = schedule?[key];
                final time =
                    value?.isAvailable == true ? value!.localCivilTime : null;
                final label = prayerDisplayNameAr(key);
                final active = key == nextKey;
                return SizedBox(
                  key: ValueKey('prayer-time-$key'),
                  width: constraints.maxWidth / columns,
                  child: Semantics(
                    label:
                        '$label ${time == null ? 'غير متاح' : intl.DateFormat('HH:mm').format(time).toEasternArabic()}',
                    selected: active,
                    child: ExcludeSemantics(
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        padding: const EdgeInsets.symmetric(
                            vertical: 9, horizontal: 2),
                        decoration: BoxDecoration(
                          color: active ? AppPalette.gold : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Icon(icons[i],
                              size: 19,
                              color:
                                  active ? AppPalette.forest : AppPalette.gold),
                          const SizedBox(height: 5),
                          Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: active
                                      ? AppPalette.forest
                                      : Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                              time == null
                                  ? '—'
                                  : intl.DateFormat('HH:mm')
                                      .format(time)
                                      .toEasternArabic(),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                  color: active
                                      ? AppPalette.forest
                                      : Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      );
}
