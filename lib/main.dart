import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'services/analytics_service.dart';
import 'sections/html_content_renderer.dart';

import 'sections/tasbih_section.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:hijri/hijri_calendar.dart';

import 'data/data_manager.dart';
import 'services/quran_service.dart';
import 'services/favorites_service.dart';
import 'services/prayer_alarm_service.dart';
import 'sections/favorites_section.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/search_engine.dart';
import 'search/screens/search_screen.dart';
import 'ui/calendar/hijri_calendar_screen.dart';
import 'ui/qibla/qibla_screen.dart';

import 'ui/widgets/app_drawer.dart';
import 'ui/splash_screen.dart';
import 'ui/home/home_section.dart';
import 'ui/about/about_section.dart';
import 'ui/tabs/tabbed_section.dart';
import 'ui/dynamic_list/dynamic_list_section.dart';
import 'ui/reader/reader_page.dart';
import 'ui/settings/settings_section.dart';
import 'ui/prayer_times/prayer_times_section.dart';

import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/screens/istikhara_screen.dart';

class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const double step = 60;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final center = Offset(x, y);
        _drawStar(canvas, center, step * 0.4, paint);
        canvas.drawCircle(center, step * 0.1, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * pi / 180;
      double x = center.dx + radius * cos(angle);
      double y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      double nextAngle = (i * 45 + 22.5) * pi / 180;
      double nextX = center.dx + (radius * 0.7) * cos(nextAngle);
      double nextY = center.dy + (radius * 0.7) * sin(nextAngle);
      path.lineTo(nextX, nextY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

IconData getMaterialIcon(String? name) {
  const iconMap = {
    'menu_book': Icons.menu_book,
    'auto_stories': Icons.auto_stories,
    'place': Icons.place,
    'translate': Icons.translate,
    'bedtime': Icons.bedtime,
    'history_edu': Icons.history_edu,
    'shield': Icons.shield,
    'favorite': Icons.favorite,
    'home': Icons.home,
    'settings': Icons.settings,
    'person': Icons.person,
    'notes': Icons.notes,
    'notifications': Icons.notifications,
    'search': Icons.search,
    'mosque': Icons.mosque,
    'book': Icons.book,
    'event': Icons.event,
    'info': Icons.info,
    'group': Icons.group,
    'verified': Icons.verified,
    'code': Icons.code,
  };
  return iconMap[name] ?? Icons.star;
}

Widget buildImage(String? path, {double? height, BoxFit fit = BoxFit.contain}) {
  if (path == null || path.isEmpty) {
    return const SizedBox();
  }
  if (path.startsWith('/')) { // Check for local file path
      final file = File(path);
      if (file.existsSync()) return Image.file(file, height: height, fit: fit);
  }
  if (path.startsWith('data:image')) {
    try {
      final bytes = Uri.parse(path).data!.contentAsBytes();
      return Image.memory(
        Uint8List.fromList(bytes),
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
      );
    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }
  if (path.startsWith('https://')) {
    return Image.network(
      path,
      height: height,
      fit: fit,
      errorBuilder: (c, e, s) => const Icon(Icons.error),
    );
  }
  return Image.asset(
    path,
    height: height,
    fit: fit,
    errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قواعد البيانات المحلية السريعة أولاً ليتمكن التطبيق من الإقلاع فوراً
  await Hive.initFlutter();
  await FavoritesService.instance.init();

  // تشغيل الواجهة فوراً لإنهاء شاشة الانتظار
  runApp(const AlDhakereenApp());

  // تهيئة الخدمات الثقيلة في الخلفية لتجنب تجميد الشاشة
  _initializeHeavyServices();
}

Future<void> _initializeHeavyServices() async {
  try {
    await Firebase.initializeApp();
    AnalyticsService().checkAndRegisterDevice();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  try {
    await PrayerAlarmService.init();
  } catch (e) {
    debugPrint("PrayerAlarmService initialization error: $e");
  }
}

class AlDhakereenApp extends StatefulWidget {
  const AlDhakereenApp({super.key});
  @override
  State<AlDhakereenApp> createState() => _AlDhakereenAppState();
}

class _AlDhakereenAppState extends State<AlDhakereenApp> {
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSizeFactor = 1.0;
  Color _primaryColor = Colors.blue;
  double _uiOpacity = 1.0;
  String? _backgroundImagePath;
  String? _selectedBase64Bg;
  Color _cardColor = Colors.white;
  Map<String, bool> _homeVisibility = {};
  int _hijriAdjustment = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    DataManager.dbNotifier.addListener(_loadSettings);
  }

  @override
  void dispose() {
    DataManager.dbNotifier.removeListener(_loadSettings);
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dbSettings = DataManager.getSettings();
    int defaultPrimary =
        int.tryParse(dbSettings['primary_color'] ?? '0xFF2196F3') ?? 0xFF2196F3;
    int defaultCard =
        int.tryParse(dbSettings['card_color'] ?? '0xFFFFFFFF') ?? 0xFFFFFFFF;
    if (mounted) {
      setState(() {
        _themeMode = (prefs.getString('theme') ?? 'light') == 'light'
            ? ThemeMode.light
            : ThemeMode.dark;
        _fontSizeFactor = prefs.getDouble('fontSize') ?? 1.0;
        _primaryColor = Color(prefs.getInt('primaryColor') ?? defaultPrimary);
        _uiOpacity = prefs.getDouble('uiOpacity') ??
            (dbSettings['ui_opacity']?.toDouble() ?? 1.0);
        _backgroundImagePath = prefs.getString('backgroundImage');
        _selectedBase64Bg = prefs.getString('custom_bg_base64_selected');
        _cardColor = Color(prefs.getInt('cardColor') ?? defaultCard);
        _hijriAdjustment = prefs.getInt('hijri.date.correction.value') ?? 0;
        final sections = DataManager.getSections();
        final allSections = {
          ...sections,
          'hadith': {},
          'names_allah': {},
          'adhkar': {},
        };
        _homeVisibility = {};
        allSections.forEach((key, value) {
          _homeVisibility[key] =
              prefs.getBool('vis_$key') ?? (value['visible_home'] ?? true);
        });
        _homeVisibility['inspiration'] = prefs.getBool('vis_inspiration') ??
            (dbSettings['show_inspiration'] ?? true);
        _homeVisibility['day_dua'] = prefs.getBool('vis_day_dua') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) prefs.setString(key, value);
    if (value is double) prefs.setDouble(key, value);
    if (value is int) prefs.setInt(key, value);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      _saveSetting('theme', _themeMode == ThemeMode.light ? 'light' : 'dark');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الذاكرين',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler:
              MediaQuery.of(context).textScaler, // Respects system font scaling
        ),
        child: child!,
      ),
      navigatorObservers: [routeObserver],
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Cairo'),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
          primary: _primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Cairo'),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
          primary: _primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      themeMode: _themeMode,
      home: SplashScreen(
        themeMode: _themeMode,
        fontSizeFactor: _fontSizeFactor,
        onFontSizeChanged: (val) {
          setState(() => _fontSizeFactor = val);
          _saveSetting('fontSize', val);
        },
        onThemeToggled: _toggleTheme,
        primaryColor: _primaryColor,
        onColorChanged: (c) {
          setState(() => _primaryColor = c);
          _saveSetting('primaryColor', c.toARGB32());
        },
        uiOpacity: _uiOpacity,
        onOpacityChanged: (val) {
          setState(() => _uiOpacity = val);
          _saveSetting('uiOpacity', val);
        },
        backgroundImagePath: _backgroundImagePath,
        selectedBase64Bg: _selectedBase64Bg,
        onBackgroundImageChanged: (path) async {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            _backgroundImagePath = path;
            if (path != null) {
              _selectedBase64Bg = null;
              prefs.remove('custom_bg_base64_selected');
            }
          });
          if (path != null) _saveSetting('backgroundImage', path);
        },
        onBase64BgChanged: (base64) {
          setState(() {
            _selectedBase64Bg = base64;
            _backgroundImagePath = null;
          });
        },
        cardColor: _cardColor,
        onCardColorChanged: (c) {
          setState(() => _cardColor = c);
          _saveSetting('cardColor', c.toARGB32());
        },
        homeVisibility: _homeVisibility,
        onVisibilityChanged: (key, val) async {
          setState(() => _homeVisibility[key] = val);
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool('vis_$key', val);
        },
        hijriAdjustment: _hijriAdjustment,
        onHijriAdjustmentChanged: (val) async {
          setState(() => _hijriAdjustment = val);
          final prefs = await SharedPreferences.getInstance();
          prefs.setInt('hijri.date.correction.value', val);
        },
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final ThemeMode themeMode;
  final double fontSizeFactor;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onThemeToggled;
  final Color primaryColor;
  final ValueChanged<Color> onColorChanged;
  final double uiOpacity;
  final ValueChanged<double> onOpacityChanged;
  final String? backgroundImagePath;
  final String? selectedBase64Bg;
  final ValueChanged<String?> onBackgroundImageChanged;
  final ValueChanged<String?> onBase64BgChanged;
  final Color cardColor;
  final ValueChanged<Color> onCardColorChanged;
  final Map<String, bool> homeVisibility;
  final void Function(String, bool) onVisibilityChanged;
  final int hijriAdjustment;
  final ValueChanged<int> onHijriAdjustmentChanged;

  const MainScaffold({
    super.key,
    required this.themeMode,
    required this.fontSizeFactor,
    required this.onFontSizeChanged,
    required this.onThemeToggled,
    required this.primaryColor,
    required this.onColorChanged,
    required this.uiOpacity,
    required this.onOpacityChanged,
    required this.backgroundImagePath,
    required this.selectedBase64Bg,
    required this.onBackgroundImageChanged,
    required this.onBase64BgChanged,
    required this.cardColor,
    required this.onCardColorChanged,
    required this.homeVisibility,
    required this.onVisibilityChanged,
    required this.hijriAdjustment,
    required this.onHijriAdjustmentChanged,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  String _currentSection = 'home';
  final List<String> _history = ['home'];

  void _navigateTo(String section) {
    if (_currentSection == section) return;
    setState(() {
      _history.add(section);
      _currentSection = section;
    });
  }

  void _onBack() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _currentSection = _history.last;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSubPage = _history.length > 1;
    return ValueListenableBuilder<int>(
        valueListenable: DataManager.dbNotifier,
        builder: (context, _, __) {
          final settings = DataManager.getSettings();
          return PopScope(
            canPop: !isSubPage,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _onBack();
            },
            child: Scaffold(
              drawer: AppDrawer(
                currentSection: _currentSection,
                onNavigate: (section) {
                  Navigator.pop(context);
                  _navigateTo(section);
                },
              ),
              appBar: AppBar(
                title: Text(
                  _getAppBarTitle(_currentSection),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
                centerTitle: true,
                elevation: 0,
                backgroundColor: Theme.of(
                  context,
                )
                    .appBarTheme
                    .backgroundColor
                    ?.withValues(alpha: widget.uiOpacity),
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.notes),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: 'القائمة',
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchScreen(
                              fontSizeFactor: widget.fontSizeFactor),
                        ),
                      );
                    },
                    tooltip: 'بحث شامل',
                  ),
                  if (isSubPage)
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: _onBack,
                      tooltip: 'رجوع',
                    ),
                  if (!isSubPage) const SizedBox(width: 4),
                ],
              ),
              body: Stack(
                children: [
                  if (_currentSection == 'home') ...[
                    if (widget.backgroundImagePath != null)
                      Positioned.fill(
                        child: Image.file(
                          File(widget.backgroundImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (widget.backgroundImagePath == null)
                      Positioned.fill(
                        child: buildImage(
                          widget.selectedBase64Bg ??
                              settings['custom_bg_base64']?.toString() ??
                              settings['bg_image']?.toString(),
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: CustomPaint(
                        painter: IslamicPatternPainter(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _buildBody(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentSection) {
      case 'home':
        return HomeSection(
          key: const ValueKey('home'),
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
          cardColor: widget.cardColor,
          visibility: widget.homeVisibility,
          hijriAdjustment: widget.hijriAdjustment,
          onPrayerCardTap: () => _navigateTo('prayer_times'),
        );
      case 'settings':
        return SettingsSection(
          key: const ValueKey('settings'),
          onThemeToggled: widget.onThemeToggled,
          primaryColor: widget.primaryColor,
          onColorChanged: widget.onColorChanged,
          uiOpacity: widget.uiOpacity,
          onOpacityChanged: widget.onOpacityChanged,
          onBackgroundImageChanged: widget.onBackgroundImageChanged,
          onBase64BgChanged: widget.onBase64BgChanged,
          backgroundImagePath: widget.backgroundImagePath,
          cardColor: widget.cardColor,
          onCardColorChanged: widget.onCardColorChanged,
          visibility: widget.homeVisibility,
          onVisibilityChanged: widget.onVisibilityChanged,
          hijriAdjustment: widget.hijriAdjustment,
          onHijriAdjustmentChanged: widget.onHijriAdjustmentChanged,
        );

      case 'favorites':
        return FavoritesSection(
          key: const ValueKey('favorites'),
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'about':
        return const AboutSection(key: ValueKey('about'));
      case 'tasbih':
        return const TasbihSection(key: ValueKey('tasbih'));
      case 'prayer_times':
        return const PrayerTimesSection(key: ValueKey('prayer_times'));
      case 'qibla':
        return QiblaScreen();
      case 'calendar':
        return HijriCalendarScreen();
      case 'duas':
        return TabbedSection(
          key: const ValueKey('duas'),
          tabs: const [
            'أدعية الأيام',
            'تعقيبات الصلاة',
            'الأدعية العامة',
            'الصلوات',
          ],
          sectionKeys: const [
            'duas_days',
            'duas_taqeebat',
            'duas_general',
            'duas_salawat',
          ],
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'visits':
        return TabbedSection(
          key: const ValueKey('visits'),
          tabs: const ['زيارات الأيام', 'الزيارات العامة'],
          sectionKeys: const ['visits_days', 'visits_general'],
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'adhkar':
        return TabbedSection(
          key: const ValueKey('adhkar'),
          tabs: const ['المناجاة', 'التسبيحات'],
          sectionKeys: const ['adhkar_munajat', 'adhkar_tasbihs'],
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'imam_ali':
        final imamAliCats = DataManager.getItems('imam_ali');
        if (imamAliCats.isEmpty) {
          return const Center(child: Text('لا يوجد محتوى متوفر حالياً'));
        }
        return TabbedSection(
          key: const ValueKey('imam_ali'),
          tabs: imamAliCats.map((c) => c['title'].toString()).toList(),
          sectionKeys:
              imamAliCats.map((c) => 'imam_ali_cat_${c['id']}').toList(),
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'dreams':
        final dreamsCats = DataManager.getItems('dreams');
        if (dreamsCats.isEmpty) {
          return const Center(child: Text('لا يوجد محتوى متوفر حالياً'));
        }
        return TabbedSection(
          key: const ValueKey('dreams'),
          tabs: dreamsCats.map((c) => c['title'].toString()).toList(),
          sectionKeys: dreamsCats.map((c) => 'dreams_cat_${c['id']}').toList(),
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'fatawa':
        final fatawaCats = DataManager.getItems('fatawa');
        if (fatawaCats.isEmpty) {
          return const Center(child: Text('لا يوجد محتوى متوفر حالياً'));
        }
        return TabbedSection(
          key: const ValueKey('fatawa'),
          tabs: fatawaCats.map((c) => c['title'].toString()).toList(),
          sectionKeys: fatawaCats.map((c) => 'fatawa_cat_${c['id']}').toList(),
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'prophets_stories':
        return DynamicListSection(
          key: const ValueKey('prophets_stories'),
          title: _getSectionTitle('prophets_stories'),
          sectionKey: 'prophets_stories',
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
      case 'istikhara':
        return IstikharaScreen(key: const ValueKey('istikhara'));
      default:
        return DynamicListSection(
          key: ValueKey(_currentSection),
          title: _getSectionTitle(_currentSection),
          sectionKey: _currentSection,
          fontSizeFactor: widget.fontSizeFactor,
          uiOpacity: widget.uiOpacity,
        );
    }
  }

  String _getSectionTitle(String key) {
    final sections = DataManager.getSections();
    if (sections.containsKey(key)) return sections[key]['title'].toString();
    return 'المحتوى';
  }

  String _getAppBarTitle(String section) {
    if (section == 'home') return 'الذاكرين';
    if (section == 'settings') return 'الإعدادات';
    if (section == 'about') return 'حول المطور';
    if (section == 'universal_batch') return 'استيراد بالدفعة';
    return _getSectionTitle(section);
  }
}

Color? _parseColor(String? colorString) {
  if (colorString == null || colorString.isEmpty) return null;
  try {
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    }
    return Color(int.parse(colorString));
  } catch (e) {
    return null;
  }
}
