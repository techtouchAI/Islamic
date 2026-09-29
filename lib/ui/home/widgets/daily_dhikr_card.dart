import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/string_extensions.dart';

/// A personal daily goal, separate from the existing tasbih al-Zahra state.
/// The target is a UI goal, not a prescribed religious count.
class DailyDhikrCard extends StatefulWidget {
  const DailyDhikrCard({super.key});
  @override
  State<DailyDhikrCard> createState() => _DailyDhikrCardState();
}

class _DailyDhikrCardState extends State<DailyDhikrCard> {
  static const _target = 100;
  int _count = 0;
  String _date = '';
  SharedPreferences? _prefs;
  bool _failed = false;
  Timer? _dayTimer;
  Future<void> _writes = Future<void>.value();

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _load();
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_prefs != null && _date != _today && mounted) {
        setState(() {
          _date = _today;
          _count = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _date = _today;
        final saved = prefs.getString('home_daily_dhikr')?.split('|');
        _count = saved?.length == 2 && saved![0] == _date
            ? (int.tryParse(saved[1]) ?? 0).clamp(0, _target)
            : 0;
        _failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _increment() {
    if (_prefs == null) return;
    setState(() {
      if (_date != _today) {
        _date = _today;
        _count = 0;
      }
      if (_count < _target) _count++;
    });
    _persist();
  }

  void _persist() {
    final value = '$_date|$_count';
    _writes = _writes.then((_) async {
      final saved = await _prefs!.setString('home_daily_dhikr', value);
      if (!saved) throw StateError('Unable to save daily dhikr');
      if (mounted && _failed) setState(() => _failed = false);
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ذكر اليوم',
                style: TextStyle(
                    color: theme.cardColor.computeLuminance() > .5
                        ? const Color(0xFF123C32)
                        : Colors.white70)),
            const SizedBox(height: 8),
            Text('سبحان الله وبحمده',
                style: TextStyle(
                    fontFamily: 'OmarNaskh',
                    fontSize: 26,
                    color: theme.cardColor.computeLuminance() > .5
                        ? Colors.black87
                        : Colors.white)),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: _count / _target,
              minHeight: 5,
              borderRadius: BorderRadius.circular(8),
              semanticsLabel: 'تقدم هدف الذكر الشخصي',
              semanticsValue: '$_count من $_target'.toEasternArabic(),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              key: const ValueKey('daily-dhikr-increment'),
              onPressed:
                  _prefs == null || (_count == _target && _date == _today)
                      ? null
                      : _increment,
              icon: Icon(
                  _count == _target ? Icons.check_circle_outline : Icons.add),
              label: Text(_count == _target
                  ? 'أتممت هدف اليوم · ١٠٠'
                  : 'تسبيح · $_count / $_target'.toEasternArabic()),
            ),
            Text('هدف يومي شخصي',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: theme.cardColor.computeLuminance() > .5
                        ? Colors.black54
                        : Colors.white70)),
            if (_failed)
              TextButton(
                  onPressed: _prefs == null ? _load : _persist,
                  child: const Text('تعذّر حفظ التقدم · إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
