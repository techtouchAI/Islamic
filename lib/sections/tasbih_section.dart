// Design: مسبحة عربية هادئة تستلهم المرجع المرئي، لكنها تستخدم ألوان وثيم الذاكرين وتبقي منطق العد والحفظ مستقلاً عن الواجهة.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tasbih_state.dart';
import '../utils/string_extensions.dart';

enum TasbihSelection {
  subhanAllah,
  alhamdulillah,
  laIlahaIllallah,
  allahuAkbar,
  astaghfirullah,
  salawat,
  tasbihAlZahra,
}

enum TasbihMode { singleDhikr, tasbihAlZahra }

class TasbihSection extends StatefulWidget {
  const TasbihSection({super.key});

  @override
  State<TasbihSection> createState() => _TasbihSectionState();
}

class _TasbihSectionState extends State<TasbihSection> {
  static const Map<TasbihSelection, String> _labels = <TasbihSelection, String>{
    TasbihSelection.subhanAllah: 'سبحان الله',
    TasbihSelection.alhamdulillah: 'الحمد لله',
    TasbihSelection.laIlahaIllallah: 'لا إله إلا الله',
    TasbihSelection.allahuAkbar: 'الله أكبر',
    TasbihSelection.astaghfirullah: 'أستغفر الله',
    TasbihSelection.salawat: 'اللهم صل على محمد وآل محمد',
    TasbihSelection.tasbihAlZahra: 'تسبيحة الزهراء',
  };

  static const Map<TasbihSelection, String> _legacyLifetimeKeys =
      <TasbihSelection, String>{
    TasbihSelection.subhanAllah: 'سبحان الله',
    TasbihSelection.alhamdulillah: 'الحمد لله',
    TasbihSelection.laIlahaIllallah: 'لا إله إلا الله',
    TasbihSelection.allahuAkbar: 'الله أكبر',
    TasbihSelection.astaghfirullah: 'أستغفر الله',
    TasbihSelection.salawat: 'اللهم صل على محمد وآل محمد',
  };

  /// A first-time visitor enters Tasbih al-Zahra. A deliberate open-dhikr
  /// choice is retained for later visits as an explicit user preference.
  TasbihSelection _selection = TasbihSelection.tasbihAlZahra;
  TasbihMode _mode = TasbihMode.tasbihAlZahra;
  int _counter = 0;
  int _lifetimeCounter = 0;
  int _zahraStageIndex = 0;
  int _completedCycles = 0;
  bool _loading = true;
  Future<void> _saveQueue = Future<void>.value();
  int _loadGeneration = 0;

  TasbihStageDefinition get _currentStage =>
      TasbihZahraState.stages[_zahraStageIndex];

  String get _currentLabel => _mode == TasbihMode.tasbihAlZahra
      ? _currentStage.label
      : _labels[_selection]!;

  int? get _target =>
      _mode == TasbihMode.tasbihAlZahra ? _currentStage.target : null;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final generation = ++_loadGeneration;
    final prefs = await SharedPreferences.getInstance();
    final savedSelection =
        _selectionFromName(prefs.getString('tasbih_selection'));
    final isZahra = prefs.getBool('tasbih_zahra_mode') ?? true;
    final savedStage =
        (prefs.getInt('tasbih_zahra_stage') ?? 0).clamp(0, 2).toInt();
    final savedCount = prefs.getInt('tasbih_zahra_count') ?? 0;
    final savedCycles = prefs.getInt('tasbih_zahra_completed_cycles') ?? 0;
    final selection = isZahra ? TasbihSelection.tasbihAlZahra : savedSelection;
    final lifetime = isZahra
        ? prefs.getInt('lifetime_tasbih_zahra') ?? 0
        : _readLegacyLifetime(prefs, selection);

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _selection = selection;
      _mode = isZahra ? TasbihMode.tasbihAlZahra : TasbihMode.singleDhikr;
      _zahraStageIndex = savedStage;
      _counter = isZahra
          ? savedCount
              .clamp(0, TasbihZahraState.stages[savedStage].target - 1)
              .toInt()
          : 0;
      _completedCycles = savedCycles < 0 ? 0 : savedCycles;
      _lifetimeCounter = lifetime < 0 ? 0 : lifetime;
      _loading = false;
    });
  }

  int _readLegacyLifetime(SharedPreferences prefs, TasbihSelection selection) {
    final legacyLabel = _legacyLifetimeKeys[selection];
    if (legacyLabel == null) return 0;
    return prefs.getInt('lifetime_tasbih_$legacyLabel') ?? 0;
  }

  TasbihSelection _selectionFromName(String? name) {
    for (final value in TasbihSelection.values) {
      if (value.name == name && value != TasbihSelection.tasbihAlZahra) {
        return value;
      }
    }
    return TasbihSelection.subhanAllah;
  }

  Future<void> _persistState() {
    final mode = _mode;
    final selection = _selection;
    final counter = _counter;
    final lifetime = _lifetimeCounter;
    final stage = _zahraStageIndex;
    final cycles = _completedCycles;
    _saveQueue = _saveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (mode == TasbihMode.tasbihAlZahra) {
        await prefs.setBool('tasbih_zahra_mode', true);
        await prefs.setInt('tasbih_zahra_stage', stage);
        await prefs.setInt('tasbih_zahra_count', counter);
        await prefs.setInt('tasbih_zahra_completed_cycles', cycles);
        await prefs.setInt('lifetime_tasbih_zahra', lifetime);
      } else {
        await prefs.setBool('tasbih_zahra_mode', false);
        await prefs.setString('tasbih_selection', selection.name);
        final legacyLabel = _legacyLifetimeKeys[selection];
        if (legacyLabel != null) {
          await prefs.setInt('lifetime_tasbih_$legacyLabel', lifetime);
        }
      }
    });
    return _saveQueue;
  }

  Future<void> _switchSelection(TasbihSelection? value) async {
    if (value == null ||
        (value == _selection &&
            ((value == TasbihSelection.tasbihAlZahra) ==
                (_mode == TasbihMode.tasbihAlZahra)))) {
      return;
    }

    final generation = ++_loadGeneration;
    final prefs = await SharedPreferences.getInstance();
    if (value == TasbihSelection.tasbihAlZahra) {
      final stage =
          (prefs.getInt('tasbih_zahra_stage') ?? 0).clamp(0, 2).toInt();
      final count = prefs.getInt('tasbih_zahra_count') ?? 0;
      final cycles = prefs.getInt('tasbih_zahra_completed_cycles') ?? 0;
      final lifetime = prefs.getInt('lifetime_tasbih_zahra') ?? 0;
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _selection = value;
        _mode = TasbihMode.tasbihAlZahra;
        _zahraStageIndex = stage;
        _counter =
            count.clamp(0, TasbihZahraState.stages[stage].target - 1).toInt();
        _completedCycles = cycles < 0 ? 0 : cycles;
        _lifetimeCounter = lifetime < 0 ? 0 : lifetime;
      });
    } else {
      final lifetime = _readLegacyLifetime(prefs, value);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _selection = value;
        _mode = TasbihMode.singleDhikr;
        _counter = 0;
        _completedCycles = 0;
        _lifetimeCounter = lifetime < 0 ? 0 : lifetime;
      });
    }
    await _persistState();
  }

  Future<void> _handleTap() async {
    if (_loading) return;

    String? stageMessage;
    var cycleCompleted = false;
    if (_mode == TasbihMode.tasbihAlZahra) {
      final previous = TasbihZahraState(
        stageIndex: _zahraStageIndex,
        count: _counter,
        completedCycles: _completedCycles,
        lifetimeTotal: _lifetimeCounter,
      );
      final next = previous.increment();
      cycleCompleted = next.completedCycles > previous.completedCycles;
      if (!cycleCompleted && next.stageIndex != previous.stageIndex) {
        stageMessage =
            'اكتملت ${previous.stage.label}، ننتقل إلى ${next.stage.label}';
      }
      setState(() {
        _zahraStageIndex = next.stageIndex;
        _counter = next.count;
        _completedCycles = next.completedCycles;
        _lifetimeCounter = next.lifetimeTotal;
      });
    } else {
      setState(() {
        _counter++;
        _lifetimeCounter++;
      });
    }

    await _persistState();
    if (cycleCompleted) {
      await HapticFeedback.heavyImpact();
      if (!mounted) return;
      await _showCompletionDialog();
      return;
    }

    if (stageMessage != null) {
      await HapticFeedback.mediumImpact();
    } else if (_mode != TasbihMode.tasbihAlZahra) {
      await HapticFeedback.lightImpact();
    }
    if (stageMessage != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(stageMessage)));
    }
  }

  Future<void> _showCompletionDialog() {
    final scheme = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.fromLTRB(28, 88, 28, 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الحمد لله',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.primary,
                    fontFamily: 'OmarNaskh',
                    fontSize: 31,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'اكتمل التسبيح',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'تقبّل الله منكم صالح الأعمال',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 17),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          if (!mounted) return;
                          setState(() {
                            _zahraStageIndex = 0;
                            _counter = 0;
                          });
                          await _persistState();
                        },
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('تسبيح مرة أخرى'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('خروج'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetCounter() async {
    if (!mounted) return;
    setState(() => _counter = 0);
    await _persistState();
    await HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final scheme = Theme.of(context).colorScheme;
    final target = _target;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              _TasbihModeSelector(
                mode: _mode,
                onZahraTap: () =>
                    _switchSelection(TasbihSelection.tasbihAlZahra),
                onOpenTap: () => _switchSelection(TasbihSelection.subhanAllah),
              ),
              const SizedBox(height: 30),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey<String>('$_mode.name-$_currentLabel'),
                  children: [
                    Text(
                      _currentLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.primary,
                        fontFamily: 'OmarNaskh',
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (target != null) ...[
                      Text(
                        'المرحلة ${(_zahraStageIndex + 1).toString().toEasternArabic()} من ${TasbihZahraState.stages.length.toString().toEasternArabic()}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      _TasbihStageRail(activeStage: _zahraStageIndex),
                    ] else ...[
                      Text(
                        'عدّ مفتوح',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 14),
                      _OpenDhikrPicker(
                        value: _selection,
                        labels: _labels,
                        onChanged: _switchSelection,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (target != null)
                _TasbihCountPanel(count: _counter, target: target),
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: 'زيادة عداد $_currentLabel',
                child: _TasbihTapTarget(
                  onTap: _handleTap,
                  primaryColor: scheme.primary,
                  surfaceColor: scheme.surface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: _resetCounter,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: target == null
                        ? 'تصفير العداد'
                        : 'تصفير المرحلة الحالية',
                  ),
                  const SizedBox(width: 14),
                  _TasbihStat(
                    label: 'الإجمالي',
                    value: intl.NumberFormat.decimalPattern()
                        .format(_lifetimeCounter)
                        .toEasternArabic(),
                  ),
                  if (_mode == TasbihMode.tasbihAlZahra) ...[
                    const SizedBox(width: 14),
                    _TasbihStat(
                      label: 'الدورات',
                      value: _completedCycles.toString().toEasternArabic(),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasbihModeSelector extends StatelessWidget {
  const _TasbihModeSelector({
    required this.mode,
    required this.onZahraTap,
    required this.onOpenTap,
  });

  final TasbihMode mode;
  final VoidCallback onZahraTap;
  final VoidCallback onOpenTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TasbihModeButton(
              label: 'تسبيحة الزهراء',
              selected: mode == TasbihMode.tasbihAlZahra,
              onTap: onZahraTap,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TasbihModeButton(
              label: 'التسبيح المفتوح',
              selected: mode == TasbihMode.singleDhikr,
              onTap: onOpenTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasbihModeButton extends StatelessWidget {
  const _TasbihModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _TasbihStageRail extends StatelessWidget {
  const _TasbihStageRail({required this.activeStage});

  final int activeStage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List<Widget>.generate(TasbihZahraState.stages.length, (index) {
        final active = index <= activeStage;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsetsDirectional.only(
              start: index == 0 ? 0 : 4,
            ),
            decoration: BoxDecoration(
              color: active
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _OpenDhikrPicker extends StatelessWidget {
  const _OpenDhikrPicker({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  final TasbihSelection value;
  final Map<TasbihSelection, String> labels;
  final ValueChanged<TasbihSelection?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: DropdownButtonFormField<TasbihSelection>(
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'اختر الذكر',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        items: TasbihSelection.values
            .where((item) => item != TasbihSelection.tasbihAlZahra)
            .map(
              (item) => DropdownMenuItem<TasbihSelection>(
                value: item,
                child: Text(labels[item]!),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _TasbihCountPanel extends StatelessWidget {
  const _TasbihCountPanel({required this.count, required this.target});

  final int count;
  final int target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 210,
      decoration: BoxDecoration(
        border: Border.all(
            color: scheme.primary.withValues(alpha: 0.7), width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(child: _CounterCell(value: count, label: 'العدد')),
          Container(width: 1, height: 52, color: scheme.outlineVariant),
          Expanded(child: _CounterCell(value: target, label: 'الهدف')),
        ],
      ),
    );
  }
}

class _CounterCell extends StatelessWidget {
  const _CounterCell({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(
            value.toString().toEasternArabic(),
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          Text(label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TasbihTapTarget extends StatelessWidget {
  const _TasbihTapTarget({
    required this.onTap,
    required this.primaryColor,
    required this.surfaceColor,
  });

  final VoidCallback onTap;
  final Color primaryColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(83)),
        child: Ink(
          width: 218,
          height: 218,
          decoration: BoxDecoration(
            border: Border.all(
                color: primaryColor.withValues(alpha: 0.75), width: 2),
            borderRadius: BorderRadius.circular(83),
          ),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surfaceColor,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.12),
                    blurRadius: 22,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'اضغط',
                  style: TextStyle(
                    fontFamily: 'OmarNaskh',
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TasbihStat extends StatelessWidget {
  const _TasbihStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: scheme.primary)),
        ],
      ),
    );
  }
}
