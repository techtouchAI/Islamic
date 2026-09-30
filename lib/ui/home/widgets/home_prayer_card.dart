import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../data/repositories/calendar_repository.dart';
import '../../../models/prayer_schedule.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/next_prayer.dart';
import '../../../utils/string_extensions.dart';
import '../home_prayer_controller.dart';
import '../prayer_scene_period.dart';
import 'prayer_scene.dart';
import 'prayer_card_typography.dart';

class HomePrayerCard extends StatefulWidget {
  const HomePrayerCard({
    super.key,
    required this.hijriAdjustment,
    this.onTap,
    this.onDateTap,
    this.controller,
  });

  final int hijriAdjustment;

  /// Opens prayer times and the adhan settings; covers the whole card except
  /// the Hijri date line.
  final VoidCallback? onTap;

  /// Opens the Hijri calendar; wired to the date line only.
  final VoidCallback? onDateTap;

  final HomePrayerController? controller;

  @override
  State<HomePrayerCard> createState() => _HomePrayerCardState();
}

class _HomePrayerCardState extends State<HomePrayerCard>
    with WidgetsBindingObserver {
  /// Hero padding; the date's tap layer below mirrors it.
  static const EdgeInsets _heroPadding = EdgeInsets.fromLTRB(20, 20, 20, 22);

  /// Distance from the physical left edge that keeps the date over the artwork
  /// instead of the painted sky, matching the reference layout.
  static const double _dateInset = 66;

  static const Key _dateKey = ValueKey('prayer-date');

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
          final weekday =
              intl.DateFormat('EEEE', 'ar_SA').format(_controller.localNow);
          final date =
              '$weekday، ${hijri.day} ${hijri.monthName} ${hijri.year} هـ'
                  .toEasternArabic();
          final remaining = upcoming?.utcTime.difference(_controller.nowUtc);
          final title = upcoming == null
              ? 'أوقات الصلاة'
              : upcoming.key == 'imsak'
                  ? 'الإمساك'
                  : 'صلاة ${prayerDisplayNameAr(upcoming.key)}';

          final period = prayerScenePeriod(
            localNow: _controller.localNow,
            schedule: _controller.today,
          );
          return Material(
            key: const ValueKey('home-prayer-card'),
            color: AppPalette.forest,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            Positioned.fill(child: PrayerScene(period: period)),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 210),
                              child: Padding(
                                padding: _heroPadding,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // The sky lives on the physical left in both
                                    // directions, matching the reference artwork.
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: _dateInset,
                                      ),
                                      child: _buildDateSpacer(date),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(title,
                                        key: const ValueKey('prayer-title'),
                                        textAlign: TextAlign.center,
                                        style: PrayerCardTypography.title),
                                    if (_controller.loading)
                                      const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(
                                            child: CircularProgressIndicator(
                                          color: AppPalette.gold,
                                          semanticsLabel:
                                              'جارٍ تحميل مواقيت الصلاة',
                                        )),
                                      )
                                    else if (remaining != null) ...[
                                      Semantics(
                                        label:
                                            'الوقت المتبقي ${_countdown(remaining)}',
                                        child: ExcludeSemantics(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(_countdown(remaining),
                                                key: const ValueKey(
                                                    'prayer-countdown'),
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: PrayerCardTypography
                                                    .countdown),
                                          ),
                                        ),
                                      ),
                                      Text(
                                          upcoming!.key == 'imsak'
                                              ? 'المتبقي للإمساك'
                                              : 'المتبقي للأذان',
                                          textAlign: TextAlign.center,
                                          style: PrayerCardTypography.caption),
                                    ] else if (!_controller.failed)
                                      const Text('لا توجد مواقيت متاحة حالياً',
                                          textAlign: TextAlign.center,
                                          style: PrayerCardTypography.caption),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Keep the five actual times inside the card; unlike the
                        // reference's six columns, sunrise is not a sixth prayer.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Column(children: [
                            PrayerTimesStrip(
                              schedule: _controller.today,
                              nextKey: upcoming != null &&
                                      _controller
                                              .today?[upcoming.key]?.utcTime ==
                                          upcoming.utcTime
                                  ? upcoming.key
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                                '${_controller.today?.location.displayName ?? 'الموقع المختار'} · عرض المواقيت وإعدادات الأذان',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.white70,
                                    fontSize: 11)),
                          ]),
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: Material(
                        type: MaterialType.transparency,
                        child: Semantics(
                          label: 'فتح مواقيت الصلاة وإعدادات الأذان',
                          button: widget.onTap != null,
                          child: InkWell(onTap: widget.onTap),
                        ),
                      ),
                    ),
                    // Sits above the card-wide tap layer, so the date opens the
                    // Hijri calendar instead of the prayer times.
                    Positioned(
                      top: _heroPadding.top,
                      left: _heroPadding.left + _dateInset,
                      right: _heroPadding.right,
                      child: _buildDateTapTarget(date),
                    ),
                  ],
                ),
                // Natural height for retry at accessibility text sizes.
                if (_controller.failed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: TextButton.icon(
                      onPressed: _controller.refresh,
                      icon: const Icon(Icons.refresh),
                      label:
                          const Text('تعذّر تحديث المواقيت · إعادة المحاولة'),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.white),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  /// Invisible copy of the date line. It reserves exactly the space the
  /// visible line occupies in the tap layer, so both copies stay in sync.
  Widget _buildDateSpacer(String date) => Visibility(
        visible: false,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: _dateLine(date, interactive: false),
      );

  /// The date line that reacts to taps: it owns the calendar gesture.
  Widget _buildDateTapTarget(String date) => widget.onDateTap == null
      ? _dateLine(date, interactive: false)
      : _dateLine(date, interactive: true);

  /// The Hijri date plus its calendar affordance.
  ///
  /// Built twice with identical geometry: one copy reserves the space inside
  /// the card body, the other is painted over the card-wide InkWell. Only
  /// interactivity differs, so the copies cannot drift apart.
  Widget _dateLine(String date, {required bool interactive}) {
    final tappable = interactive && widget.onDateTap != null;
    final line = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            date,
            key: tappable ? _dateKey : null,
            textAlign: TextAlign.right,
            style: PrayerCardTypography.date,
          ),
        ),
        const SizedBox(width: 6),
        Opacity(
          opacity: tappable ? 1 : 0,
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: Color(0x8CF5F1DC),
          ),
        ),
      ],
    );
    if (!tappable) return line;
    return Semantics(
      button: true,
      label: 'فتح التقويم الهجري',
      onTap: widget.onDateTap,
      child: ExcludeSemantics(
        child: InkWell(
          key: const ValueKey('prayer-date-button'),
          onTap: widget.onDateTap,
          borderRadius: BorderRadius.circular(10),
          child: line,
        ),
      ),
    );
  }

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
              color: const Color(0xFFF5F0DF),
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
                          color:
                              active ? AppPalette.forest : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Icon(icons[i],
                              size: 19,
                              color: active
                                  ? AppPalette.gold
                                  : const Color(0xFF897547)),
                          const SizedBox(height: 5),
                          Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: active
                                      ? AppPalette.gold
                                      : AppPalette.forest)),
                          const SizedBox(height: 4),
                          Text(
                              time == null
                                  ? '—'
                                  : intl.DateFormat('HH:mm')
                                      .format(time)
                                      .toEasternArabic(),
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  fontFamily: 'OmarNaskh',
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight: FontWeight.w500,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                  color: active
                                      ? AppPalette.gold
                                      : AppPalette.forest)),
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
