import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/string_extensions.dart';
import '../models/tasbih_state.dart';

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

  TasbihSelection _selection = TasbihSelection.subhanAllah;
  TasbihMode _mode = TasbihMode.singleDhikr;
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
    final isZahra = prefs.getBool('tasbih_zahra_mode') ?? false;
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
        value == _selection &&
            ((value == TasbihSelection.tasbihAlZahra) ==
                (_mode == TasbihMode.tasbihAlZahra))) {
      return;
    }

    final generation = ++_loadGeneration;
    if (value == TasbihSelection.tasbihAlZahra) {
      final prefs = await SharedPreferences.getInstance();
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
      final prefs = await SharedPreferences.getInstance();
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

    String? completionMessage;
    if (_mode == TasbihMode.tasbihAlZahra) {
      final previous = TasbihZahraState(
        stageIndex: _zahraStageIndex,
        count: _counter,
        completedCycles: _completedCycles,
        lifetimeTotal: _lifetimeCounter,
      );
      final next = previous.increment();
      if (next.stageIndex != previous.stageIndex) {
        completionMessage = next.completedCycles > previous.completedCycles
            ? 'اكتملت تسبيحة الزهراء، ابدأ دورة جديدة'
            : 'انتهت ${previous.stage.label}، ابدأ ${next.stage.label} ${next.stage.target} مرة';
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

    await HapticFeedback.lightImpact();
    await _persistState();

    if (completionMessage != null) {
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(completionMessage)));
    }
  }

  Future<void> _resetCounter() async {
    if (!mounted) return;
    setState(() => _counter = 0);
    await _persistState();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final target = _target;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  _currentLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'OmarNaskh',
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (target != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'المرحلة ${_zahraStageIndex + 1} من ${TasbihZahraState.stages.length} — $_counter/$target',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: 'زيادة عداد $_currentLabel',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: _handleTap,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$_counter'.toEasternArabic(),
                            style: TextStyle(
                              fontSize: 70,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'المجموع الكلي: ${intl.NumberFormat.decimalPattern().format(_lifetimeCounter).toEasternArabic()}',
                  style: TextStyle(
                    fontFamily: 'OmarNaskh',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (_mode == TasbihMode.tasbihAlZahra)
                  Text(
                    'الدورات المكتملة: ${_completedCycles.toString().toEasternArabic()}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 30),
                onPressed: _resetCounter,
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'تصفير المرحلة الحالية',
              ),
              const SizedBox(width: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButton<TasbihSelection>(
                  value: _selection,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onChanged: _switchSelection,
                  items: TasbihSelection.values
                      .map(
                        (value) => DropdownMenuItem<TasbihSelection>(
                          value: value,
                          child: Text(
                            _labels[value]!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
