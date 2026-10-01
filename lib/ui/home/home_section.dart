import 'package:flutter/material.dart';

import 'package:intl/intl.dart' as intl;

import 'dart:async';
import 'dart:math';

import '../../data/data_manager.dart';
import '../../data/daily_duas.dart';
import '../../utils/content_sanitizer.dart';
import '../../utils/string_extensions.dart';
import '../../services/quran_service.dart';

import '../reader/reader_page.dart';

import '../../presentation/screens/istikhara_screen.dart';

import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../theme/app_card_theme.dart';
import '../widgets/keep_alive_host.dart';
import 'widgets/home_prayer_card.dart';
import 'widgets/daily_worship_actions.dart';
import 'widgets/daily_dhikr_card.dart';
import 'widgets/home_card_glyph.dart';
import 'widgets/prophets_tree_card.dart';

class HomeSection extends StatefulWidget {
  final VoidCallback? onPrayerCardTap;
  final VoidCallback? onHijriDateTap;
  final ValueChanged<String>? onNavigate;
  const HomeSection({
    super.key,
    this.onPrayerCardTap,
    this.onHijriDateTap,
    this.onNavigate,
  });

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  String? _cachedDuaKey;
  Map<String, dynamic>? _cachedInspirationDua;
  Map<String, dynamic>? _cachedDayDua;

  Map<String, dynamic> items = {};
  Map<String, dynamic>? _inspirationDua;
  Map<String, dynamic>? _dayDua;
  String? _itemsRevision;
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    // Date-dependent content changes without a page reload. The second ticker
    // belongs to HomePrayerCard and never rebuilds this content list.
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    super.dispose();
  }

  void _refreshItems(SettingsProvider settingsProvider) {
    final random =
        Random(int.parse(intl.DateFormat('yyyyMMdd').format(DateTime.now())));
    final sections = DataManager.getSections();
    items = {};
    sections.forEach((key, value) {
      if (key == 'mafatih' || key == 'Mafatih_alJinan') {
        return; // Hide Mafatih from Home Screen
      }
      // A section rendered by its own home card must not also appear as a
      // grid tile, or the same content would be reachable twice.
      if (value['home_card'] == true) return;
      if (settingsProvider.homeVisibility[key] ?? true) {
        String fetchKey = key;
        if (key == 'visits') fetchKey = 'visits_general';
        if (key == 'duas') fetchKey = 'duas_general';

        List<dynamic> listToPickFrom = DataManager.getItems(fetchKey);

        if (key == 'dreams' && listToPickFrom.isNotEmpty) {
          final randomCat = _safeGet(listToPickFrom, random);
          final catId = randomCat['id']?.toString();
          if (catId != null) {
            listToPickFrom = DataManager.getItems('dreams_cat_$catId');
          }
        } else if (key == 'imam_ali' && listToPickFrom.isNotEmpty) {
          final randomCat = _safeGet(listToPickFrom, random);
          final catId = randomCat['id'];
          if (catId != null) {
            listToPickFrom = DataManager.getItems('imam_ali_cat_$catId');
          }
        } else if (key == 'fatawa' && listToPickFrom.isNotEmpty) {
          final randomCat = _safeGet(listToPickFrom, random);
          if (randomCat['items'] != null && randomCat['items'] is List) {
            listToPickFrom = randomCat['items'];
          }
        }

        final safeItem = Map<String, dynamic>.from(
          _safeGet(listToPickFrom, random),
        );

        safeItem['sectionKey'] = key;
        items[value['title']] = safeItem;
      }
    });
  }

  void _loadDailyDua() {
    final now = DateTime.now();
    final dateKey = intl.DateFormat('yyyy-MM-dd').format(now);
    final cacheKey = "${dateKey}_${DataManager.dbNotifier.value}";

    if (_cachedDuaKey == cacheKey) {
      _inspirationDua = _cachedInspirationDua;
      _dayDua = _cachedDayDua;
      return;
    }

    final dayOfYear = int.parse(intl.DateFormat('D').format(now));
    _inspirationDua =
        DailyDuas.shortDuas[dayOfYear % DailyDuas.shortDuas.length];

    final dayNameAr = intl.DateFormat('EEEE', 'ar_SA').format(now);
    final allDaysDuas = DataManager.getItems('duas_days');

    final normalizedDay = dayNameAr.normalizeArabic();

    final itemsForToday = allDaysDuas.where((it) {
      final title = it['title'].toString().normalizeArabic();
      return title.contains(normalizedDay);
    }).toList();

    if (itemsForToday.isNotEmpty) {
      String combinedTitle = "أعمال يوم $dayNameAr";
      StringBuffer combinedContent = StringBuffer();
      for (var it in itemsForToday) {
        combinedContent.writeln("✨ ${it['title']} ✨");
        combinedContent.writeln("${it['content']}");
        combinedContent.writeln("");
      }
      _dayDua = {
        "title": combinedTitle,
        "content": combinedContent.toString().trim(),
      };
    } else {
      _dayDua = null;
    }

    _cachedDuaKey = cacheKey;
    _cachedInspirationDua = _inspirationDua;
    _cachedDayDua = _dayDua;
  }

  /// Section key of the collection the tree home card opens.
  static const _treeSectionKey = 'prophets_tree';

  /// The tree section, or null when the loaded document carries no entries
  /// for it: an older document then simply gets no card.
  Map<String, dynamic>? get _treeSection {
    final section = DataManager.getSections()[_treeSectionKey];
    if (section == null) return null;
    return DataManager.getItems(_treeSectionKey).isEmpty ? null : section;
  }

  dynamic _safeGet(List list, Random r) {
    if (list.isEmpty) return {'title': 'قريباً', 'content': ''};
    return list[r.nextInt(list.length)];
  }

  Widget _buildSpecialCard(
    SettingsProvider settingsProvider,
    BuildContext context,
    String tag,
    Map<String, dynamic> data,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final foreground = theme.cardColor.contrastTextColor;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.cardColor.withValues(alpha: settingsProvider.uiOpacity),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReaderPage(
                title: data['title'].toString(),
                content: data['content'].toString(),
                fontSizeFactor: settingsProvider.fontSizeFactor,
              ),
            )),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: foreground.withValues(alpha: .7), size: 22),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(tag,
                      style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: 17))),
              Icon(Icons.chevron_left, color: foreground.withValues(alpha: .5)),
            ]),
            const SizedBox(height: 12),
            Text(ContentSanitizer.plainText(data['content'].toString()),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'OmarNaskh',
                    fontSize: 20,
                    height: 1.8,
                    color: foreground)),
            const SizedBox(height: 8),
            Text(data['title'].toString(),
                style: TextStyle(
                    color: foreground.withValues(alpha: .65), fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    _loadDailyDua();
    final revision = '${intl.DateFormat('yyyy-MM-dd').format(DateTime.now())}'
        '_${DataManager.dbNotifier.value}_${settingsProvider.homeVisibility}';
    if (_itemsRevision != revision) {
      _refreshItems(settingsProvider);
      _itemsRevision = revision;
    }
    // Process items into rows for lazy loading
    List<List<MapEntry<String, dynamic>>> groupedRows = [];
    List<MapEntry<String, dynamic>> currentRow = [];

    for (var e in items.entries) {
      bool isFullWidth = MediaQuery.textScalerOf(context).scale(14) > 21 ||
          e.key.contains('علي') ||
          e.key.contains('موسوعة') ||
          e.key.contains('istikhara');
      if (isFullWidth) {
        if (currentRow.isNotEmpty) {
          groupedRows.add(List.from(currentRow));
          currentRow.clear();
        }
        groupedRows.add([e]);
      } else {
        currentRow.add(e);
        if (currentRow.length == 2) {
          groupedRows.add(List.from(currentRow));
          currentRow.clear();
        }
      }
    }
    if (currentRow.isNotEmpty) {
      groupedRows.add(List.from(currentRow));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          key: const PageStorageKey('home-scroll'),
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Kept alive so scrolling the home list never resets the
                  // loaded schedule or restarts the countdown.
                  KeepAliveHost(
                    child: HomePrayerCard(
                      hijriAdjustment: settingsProvider.hijriAdjustment,
                      onTap: widget.onPrayerCardTap,
                      onDateTap: widget.onHijriDateTap,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('العبادة اليومية',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  DailyWorshipActions(
                    onNavigate: widget.onNavigate,
                    visibility: settingsProvider.homeVisibility,
                  ),
                  const SizedBox(height: 20),
                  if (settingsProvider.homeVisibility['adhkar'] ?? true) ...[
                    const DailyDhikrCard(),
                    const SizedBox(height: 16),
                  ],
                  if (_treeSection != null &&
                      (settingsProvider.homeVisibility[_treeSectionKey] ??
                          true)) ...[
                    ProphetsTreeCard(
                      title: _treeSection!['title'].toString(),
                      uiOpacity: settingsProvider.uiOpacity,
                      onTap: () => widget.onNavigate?.call(_treeSectionKey),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_dayDua != null &&
                      (settingsProvider.homeVisibility['day_dua'] ?? true))
                    _buildSpecialCard(
                      settingsProvider,
                      context,
                      'دعاء اليوم',
                      _dayDua!,
                      Icons.calendar_today,
                    ),
                  if (_dayDua != null &&
                      (settingsProvider.homeVisibility['day_dua'] ?? true))
                    const SizedBox(height: 15),
                  if (_inspirationDua != null &&
                      (settingsProvider.homeVisibility['inspiration'] ?? true))
                    _buildSpecialCard(
                      settingsProvider,
                      context,
                      'إلهام اليوم',
                      _inspirationDua!,
                      Icons.lightbulb_outline,
                    ),
                  const SizedBox(height: 25),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'مقتطفات إيمانية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16)
                  .copyWith(bottom: 20),
              sliver: SliverList.builder(
                itemCount: groupedRows.length,
                itemBuilder: (context, index) {
                  final rowItems = groupedRows[index];

                  Widget buildCard(MapEntry<String, dynamic> e) {
                    final sectionKey = e.value['sectionKey']?.toString() ?? '';
                    final isImamAli = sectionKey.contains('imam_ali');
                    var title = e.value['title'].toString();
                    if (isImamAli) {
                      title = 'قال أمير المؤمنين علي (عليه السلام)';
                    }
                    return RepaintBoundary(
                      child: _HomeSmallCard(
                        tag: e.key,
                        title: title,
                        glyph: resolveHomeCardGlyph(
                          sectionKey: sectionKey,
                          title: title,
                        ),
                        uiOpacity: settingsProvider.uiOpacity,
                        onTap: () async {
                          if (sectionKey == 'istikhara') {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => const IstikharaScreen(),
                              ),
                            );
                            return;
                          }
                          if (e.value['title'] == 'قريباً') {
                            widget.onNavigate?.call(sectionKey);
                            return;
                          }
                          final isQuran = sectionKey == 'quran';
                          List<Map<String, dynamic>>? ayahs;
                          String contentStr = e.value['content'].toString();

                          if (isQuran) {
                            final surahId = e.value['id'];
                            if (surahId != null) {
                              ayahs = await QuranService.getAyahs(surahId);
                              contentStr = QuranService.getFormattedContent(
                                surahId,
                                ayahs,
                              );
                            }
                          }

                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => ReaderPage(
                                title: e.value['title'].toString(),
                                content: contentStr,
                                fontSizeFactor: settingsProvider.fontSizeFactor,
                                isQuran: isQuran,
                                isImamAli: sectionKey.contains('imam_ali'),
                                surahName: isQuran
                                    ? e.value['title'].toString().replaceAll(
                                          'سورة ',
                                          '',
                                        )
                                    : null,
                                ayahs: ayahs,
                                surahId: isQuran ? e.value['id'] : null,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  if (rowItems.length == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: buildCard(rowItems[0]),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: buildCard(rowItems[0])),
                        const SizedBox(width: 12.0),
                        if (rowItems.length > 1)
                          Expanded(child: buildCard(rowItems[1]))
                        else
                          const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSmallCard extends StatelessWidget {
  final String tag, title;
  final HomeCardGlyph glyph;
  final double uiOpacity;
  final VoidCallback onTap;
  const _HomeSmallCard({
    required this.tag,
    required this.title,
    required this.glyph,
    required this.uiOpacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.cardColor.contrastTextColor;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.cardColor.withValues(alpha: uiOpacity),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            HomeCardGlyphIcon(
              glyph: glyph,
              size: 26,
              color: foreground.withValues(alpha: .65),
            ),
            const SizedBox(height: 12),
            Text(tag,
                style: TextStyle(
                    fontSize: 14,
                    color: foreground,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: foreground.withValues(alpha: .65))),
          ]),
        ),
      ),
    );
  }
}
