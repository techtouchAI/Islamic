import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:io';

import 'data/data_manager.dart';
import 'data/daily_duas.dart';
import 'utils/string_extensions.dart';
import 'services/prayer_times_service.dart';
import 'services/prayer_notification_service.dart';
import 'services/quran_service.dart';
import 'data/iraq_provinces.dart';

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

Widget _buildImage(
  String? path, {
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  if (path == null || path.isEmpty) return const SizedBox();
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
  if (path.startsWith('http')) {
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlDhakereenApp());
}

class AlDhakereenApp extends StatefulWidget {
  const AlDhakereenApp({super.key});
  @override
  State<AlDhakereenApp> createState() => _AlDhakereenAppState();
}

class _AlDhakereenAppState extends State<AlDhakereenApp> {
  ThemeMode _themeMode = ThemeMode.light;
  double _fontSizeFactor = 1.0;
  Color _primaryColor = const Color(0xFFD4AF37);
  double _uiOpacity = 1.0;
  String? _backgroundImagePath;
  String? _selectedBase64Bg;
  Color _cardColor = Colors.white;
  Map<String, bool> _homeVisibility = {};
  int _hijriAdjustment = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await initializeDateFormatting('ar_SA', null);
      HijriCalendar.setLocal('ar');
      await DataManager.loadContent();
      await PrayerNotificationService.initNotifications();
      PrayerNotificationService.scheduleDailyPrayers();
      await QuranService.initDB();
      await _loadSettings();
      DataManager.syncCloudData().then((updated) {
        if (updated && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم تحديث المحتوى بنجاح',
                textAlign: TextAlign.center,
              ),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint("Initialization Error: $e");
    } finally {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dbSettings = DataManager.getSettings();
    DataManager.dbNotifier.addListener(() {
      if (mounted) setState(() {});
    });
    int defaultPrimary =
        int.tryParse(dbSettings['primary_color'] ?? '0xFFD4AF37') ?? 0xFFD4AF37;
    int defaultCard =
        int.tryParse(dbSettings['card_color'] ?? '0xFFFFFFFF') ?? 0xFFFFFFFF;
    setState(() {
      _themeMode = (prefs.getString('theme') ?? 'light') == 'light'
          ? ThemeMode.light
          : ThemeMode.dark;
      _fontSizeFactor = prefs.getDouble('fontSize') ?? 1.0;
      _primaryColor = Color(prefs.getInt('primaryColor') ?? defaultPrimary);
      _uiOpacity =
          prefs.getDouble('uiOpacity') ??
          (dbSettings['ui_opacity']?.toDouble() ?? 1.0);
      _backgroundImagePath = prefs.getString('backgroundImage');
      _selectedBase64Bg = prefs.getString('custom_bg_base64_selected');
      _cardColor = Color(prefs.getInt('cardColor') ?? defaultCard);
      _hijriAdjustment = prefs.getInt('hijriAdj') ?? 0;
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
      _homeVisibility['inspiration'] =
          prefs.getBool('vis_inspiration') ??
          (dbSettings['show_inspiration'] ?? true);
      _homeVisibility['day_dua'] = prefs.getBool('vis_day_dua') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) prefs.setString(key, value);
    if (value is double) prefs.setDouble(key, value);
    if (value is int) prefs.setInt(key, value);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
      _saveSetting('theme', _themeMode == ThemeMode.light ? 'light' : 'dark');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImage('assets/images/logo.png', height: 100),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      );
    }
    return MaterialApp(
      title: 'الذاكرين',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.notoKufiArabicTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
          primary: _primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.notoKufiArabicTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
          primary: _primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      themeMode: _themeMode,
      home: MainScaffold(
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
          prefs.setInt('hijriAdj', val);
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(
            context,
          ).appBarTheme.backgroundColor?.withValues(alpha: widget.uiOpacity),
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
                showSearch(
                  context: context,
                  delegate: GlobalSearchDelegate(
                    fontSizeFactor: widget.fontSizeFactor,
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
                  child: _buildImage(
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
      case 'about':
        return const AboutSection(key: ValueKey('about'));
      case 'tasbih':
        return const TasbihSection(key: ValueKey('tasbih'));
      case 'prayer_times':
        return const PrayerTimesSection(key: ValueKey('prayer_times'));
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

class AppDrawer extends StatelessWidget {
  final String currentSection;
  final ValueChanged<String> onNavigate;
  const AppDrawer({
    super.key,
    required this.currentSection,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final about = DataManager.getAbout();
    final settings = DataManager.getSettings();
    final sections = DataManager.getSections();
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImage(
                    settings['custom_logo_base64']?.toString() ??
                        settings['logo_image']?.toString(),
                    height: 60,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'تطبيق الذاكرين',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    about['developer_name']?.toString() ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(context, 'home', 'الرئيسية', Icons.home),
                _buildItem(
                  context,
                  'prayer_times',
                  'أوقات الصلاة',
                  Icons.access_time,
                ),
                _buildItem(
                  context,
                  'tasbih',
                  'المسبحة الإلكترونية',
                  Icons.vibration,
                ),
                ...sections.entries.map(
                  (e) => _buildItem(
                    context,
                    e.key,
                    e.value['title'],
                    getMaterialIcon(e.value['icon']),
                  ),
                ),
                const Divider(),
                _buildItem(context, 'about', 'حول المطور', Icons.person),
                _buildItem(context, 'settings', 'الإعدادات', Icons.settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String id,
    String title,
    IconData icon,
  ) {
    final bool active = currentSection == id;
    final int count = DataManager.getItems(id).length;
    return ListTile(
      leading: Icon(
        icon,
        color: active ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      trailing: count > 0 ? _CountBadge(count: count) : null,
      selected: active,
      selectedTileColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.1),
      onTap: () => onNavigate(id),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class HomeSection extends StatefulWidget {
  final double fontSizeFactor;
  final double uiOpacity;
  final Color cardColor;
  final Map<String, bool> visibility;
  final int hijriAdjustment;
  final VoidCallback? onPrayerCardTap;
  const HomeSection({
    super.key,
    required this.fontSizeFactor,
    required this.uiOpacity,
    required this.cardColor,
    required this.visibility,
    required this.hijriAdjustment,
    this.onPrayerCardTap,
  });

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  late Map<String, dynamic> items;
  Map<String, dynamic>? _inspirationDua;
  Map<String, dynamic>? _dayDua;
  Map<String, DateTime>? _prayerTimes;
  String _currentPrayerName = "";
  Timer? _prayerTimer;

  @override
  void initState() {
    super.initState();
    _refreshItems();
    _loadDailyDua();
    _initPrayerTimes();
    _prayerTimer = Timer.periodic(
      const Duration(minutes: 1),
      (t) => _updateCurrentPrayer(),
    );
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPrayerTimes() async {
    final service = PrayerTimesService();
    final pos = Position(
      latitude: 33.3128,
      longitude: 44.3615,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    _prayerTimes = service.calculatePrayerTimes(pos);
    _updateCurrentPrayer();
  }

  void _updateCurrentPrayer() {
    if (_prayerTimes == null) return;
    final now = DateTime.now();
    String next = "الفجر";
    final sorted = _prayerTimes!.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (var e in sorted) {
      if (now.isBefore(e.value)) {
        next = _getArName(e.key);
        break;
      }
    }
    if (mounted) setState(() => _currentPrayerName = next);
  }

  String _getArName(String key) {
    const map = {
      'fajr': 'الفجر',
      'sunrise': 'الشروق',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'midnight': 'منتصف الليل',
    };
    return map[key] ?? key;
  }

  void _refreshItems() {
    final random = Random();
    final sections = DataManager.getSections();
    items = {};
    sections.forEach((key, value) {
      if (widget.visibility[key] ?? true) {
        final safeItem = Map<String, dynamic>.from(
          _safeGet(DataManager.getItems(key), random),
        );
        safeItem['sectionKey'] = key;
        items[value['title']] = safeItem;
      }
    });
  }

  void _loadDailyDua() {
    final now = DateTime.now();
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
    setState(() {});
  }

  dynamic _safeGet(List list, Random r) {
    if (list.isEmpty) return {'title': 'قريباً', 'content': ''};
    return list[r.nextInt(list.length)];
  }

  Widget _buildSpecialCard(
    BuildContext context,
    String tag,
    Map<String, dynamic> data,
    Color textColor,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => ReaderPage(
            title: data['title'].toString(),
            content: data['content'].toString(),
            fontSizeFactor: widget.fontSizeFactor,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.cardColor.withValues(
                        alpha: widget.uiOpacity * 0.8,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tag,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['content'].toString(),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 17,
                        height: 1.9,
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        data["title"].toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijri = HijriCalendar.now();
    if (widget.hijriAdjustment != 0) {
      hijri.hDay += widget.hijriAdjustment;
      if (hijri.hDay > 30) {
        hijri.hDay -= 30;
        hijri.hMonth += 1;
      }
      if (hijri.hDay < 1) {
        hijri.hDay += 30;
        hijri.hMonth -= 1;
      }
    }
    final bool isDarkCard = widget.cardColor.computeLuminance() < 0.5;
    final Color textColor = isDarkCard ? Colors.white : Colors.black87;
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            InkWell(
              onTap: widget.onPrayerCardTap,
              borderRadius: BorderRadius.circular(25),
              child: Card(
                elevation: 10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: widget.uiOpacity)
                    : Colors.black.withValues(alpha: widget.uiOpacity),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.5,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 15,
                  ),
                  child: Column(
                    children: [
                      if (_currentPrayerName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "الصلاة القادمة: $_currentPrayerName",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      _ClockWidget(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        intl.DateFormat(
                          'EEEE, d MMMM yyyy',
                          'ar_SA',
                        ).format(now),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_dayDua != null && (widget.visibility['day_dua'] ?? true))
              _buildSpecialCard(
                context,
                'دعاء اليوم',
                _dayDua!,
                textColor,
                Icons.calendar_today,
              ),
            if (_dayDua != null && (widget.visibility['day_dua'] ?? true))
              const SizedBox(height: 15),
            if (_inspirationDua != null &&
                (widget.visibility['inspiration'] ?? true))
              _buildSpecialCard(
                context,
                'إلهام اليوم',
                _inspirationDua!,
                textColor,
                Icons.auto_awesome,
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items.entries
                  .map(
                    (e) => RepaintBoundary(
                      child: _HomeSmallCard(
                        tag: e.key,
                        title: e.value['title'].toString(),
                        uiOpacity: widget.uiOpacity,
                        cardColor: widget.cardColor,
                        onTap: () async {
                          final sectionKey = e.value['sectionKey'];
                          final isQuran = sectionKey == 'quran';
                          List<Map<String, dynamic>>? ayahs;
                          String contentStr = e.value['content'].toString();

                          if (isQuran) {
                            final surahId = e.value['id'];
                            if (surahId != null) {
                              ayahs = await QuranService.getAyahs(surahId);
                              contentStr = ayahs
                                  .map((a) {
                                    final text = a['ar_text'].toString().trim();
                                    final index =
                                        a['anum']?.toString() ??
                                        a['ayah_surah_index'].toString();
                                    return index.isEmpty
                                        ? text
                                        : "$text \uFD3F$index\uFD3E";
                                  })
                                  .join(" ");
                            }
                          }

                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => ReaderPage(
                                title: e.value['title'].toString(),
                                content: contentStr,
                                fontSizeFactor: widget.fontSizeFactor,
                                isQuran: isQuran,
                                surahName: isQuran
                                    ? e.value['title'].toString().replaceAll(
                                        'سورة ',
                                        '',
                                      )
                                    : null,
                                ayahs: ayahs,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSmallCard extends StatelessWidget {
  final String tag, title;
  final double uiOpacity;
  final Color cardColor;
  final VoidCallback onTap;
  const _HomeSmallCard({
    required this.tag,
    required this.title,
    required this.uiOpacity,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkCard = cardColor.computeLuminance() < 0.5;
    final Color textColor = isDarkCard ? Colors.white : Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: uiOpacity * 0.8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.star,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  final Color color;
  const _ClockWidget({required this.color});
  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late Timer _timer;
  final ValueNotifier<String> _timeNotifier = ValueNotifier<String>("");
  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _timeNotifier.dispose();
    super.dispose();
  }

  void _updateTime() {
    final String formattedTime = intl.DateFormat(
      'hh:mm:ss a',
      'en_US',
    ).format(DateTime.now());
    _timeNotifier.value = formattedTime
        .replaceFirst('AM', 'ص')
        .replaceFirst('PM', 'م');
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<String>(
        valueListenable: _timeNotifier,
        builder: (context, value, child) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: widget.color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});
  @override
  Widget build(BuildContext context) {
    final about = DataManager.getAbout();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  getMaterialIcon(
                    about['developer_icon']?.toString() ?? 'person',
                  ),
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                about['developer_name']?.toString() ?? 'المطور',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 15),
              Text(
                about['app_info']?.toString() ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 30),
              if (about['developer_page'] != null)
                ElevatedButton.icon(
                  onPressed: () =>
                      launchUrl(Uri.parse(about['developer_page'].toString())),
                  icon: const Icon(Icons.link),
                  label: const Text('زيارة الموقع الشخصي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TabbedSection extends StatelessWidget {
  final List<String> tabs;
  final List<String> sectionKeys;
  final double fontSizeFactor;
  final double uiOpacity;
  const TabbedSection({
    super.key,
    required this.tabs,
    required this.sectionKeys,
    required this.fontSizeFactor,
    required this.uiOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : const Color(0xFFFDFBF7),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
              tabs: List.generate(
                tabs.length,
                (i) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tabs[i]),
                      const SizedBox(width: 6),
                      _CountBadge(
                        count: DataManager.getItems(sectionKeys[i]).length,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: sectionKeys
                  .map(
                    (key) => DynamicListSection(
                      title: '',
                      sectionKey: key,
                      fontSizeFactor: fontSizeFactor,
                      uiOpacity: uiOpacity,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class DynamicListSection extends StatelessWidget {
  final String title;
  final String sectionKey;
  final double fontSizeFactor;
  final double uiOpacity;
  const DynamicListSection({
    super.key,
    required this.title,
    required this.sectionKey,
    required this.fontSizeFactor,
    required this.uiOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final isQuran = sectionKey == 'quran';
    if (isQuran) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: QuranService.getSurahs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: data.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              final surah = data[index];
              return Card(
                color: Theme.of(context).cardColor.withValues(alpha: uiOpacity),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  title: Text(
                    surah['name'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Scheherazade New',
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "سورة ${surah['name']} - آياتها ${surah['total_ayahs']}",
                      style: GoogleFonts.scheherazadeNew(fontSize: 18),
                    ),
                  ),
                  onTap: () async {
                    final ayahs = await QuranService.getAyahs(surah['id']);
                    final content = ayahs
                        .map((a) {
                          final text = a['ar_text'].toString().trim();
                          final index =
                              a['anum']?.toString() ??
                              a['ayah_surah_index'].toString();
                          return index.isEmpty
                              ? text
                              : "$text \uFD3F$index\uFD3E";
                        })
                        .join(" ");
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => ReaderPage(
                          title: "سورة ${surah['name']}",
                          content: content,
                          fontSizeFactor: fontSizeFactor,
                          isQuran: true,
                          surahName: surah['name'].toString(),
                          ayahs: ayahs,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    }

    final data = DataManager.getItems(sectionKey);
    return Column(
      children: [
        Expanded(
          child: data.isEmpty
              ? const Center(child: Text('لا يوجد محتوى متوفر حالياً'))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: data.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor.withValues(
                                    alpha: uiOpacity * 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            title: Text(
                              data[index]['title'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                data[index]['content'].toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.amiri(fontSize: 16),
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => ReaderPage(
                                  title: data[index]['title'].toString(),
                                  content: data[index]['content'].toString(),
                                  fontSizeFactor: fontSizeFactor,
                                  isQuran: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class SurahHeader extends StatelessWidget {
  final String title;
  final Color color;
  const SurahHeader({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 50,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              title,
              style: GoogleFonts.scheherazadeNew(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Positioned(
            left: 20,
            child: Icon(
              Icons.brightness_7,
              color: color.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          Positioned(
            right: 20,
            child: Icon(
              Icons.brightness_7,
              color: color.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class ReaderPage extends StatefulWidget {
  final String title, content;
  final double fontSizeFactor;
  final bool isQuran;
  final List<Map<String, dynamic>>? ayahs;
  final String? surahName;
  const ReaderPage({
    super.key,
    required this.title,
    required this.content,
    required this.fontSizeFactor,
    this.isQuran = false,
    this.surahName,
    this.ayahs,
  });
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late double _factor;
  Color? _customBgColor;

  String _convertToArabicNumber(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String numStr = number;
    for (int i = 0; i < english.length; i++) {
      numStr = numStr.replaceAll(english[i], arabic[i]);
    }
    return numStr;
  }

  @override
  void initState() {
    super.initState();
    _factor = widget.fontSizeFactor;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.content));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('تم نسخ النص')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(widget.content),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: primary, width: 3),
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _customBgColor ?? primary.withValues(alpha: 0.02),
                      (_customBgColor ?? primary.withValues(alpha: 0.02))
                          .withValues(alpha: 0.5),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (widget.isQuran)
                      SurahHeader(title: widget.title, color: primary),
                    if (widget.isQuran &&
                        widget.surahName != 'الفاتحة' &&
                        widget.surahName != 'التوبة') ...[
                      Text(
                        "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                        style: GoogleFonts.scheherazadeNew(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 12,
                            color: primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                    widget.isQuran &&
                            widget.ayahs != null &&
                            widget.ayahs!.isNotEmpty
                        ? RichText(
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'me_quran',
                                fontSize: 32 * _factor,
                                height: 1.8,
                                color: _customBgColor != null
                                    ? (_customBgColor!.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white)
                                    : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color ??
                                          Colors.black,
                              ),
                              children: widget.ayahs!.map((a) {
                                String text = a['ar_text'].toString().trim();
                                final index =
                                    a['anum']?.toString() ??
                                    a['ayah_surah_index'].toString();
                                final arabicIndex = _convertToArabicNumber(
                                  index,
                                );

                                // Remove trailing english or arabic numbers from the text itself
                                text = text
                                    .replaceAll(
                                      RegExp(r'[\s\xa0]*[0-9٠-٩]+$'),
                                      '',
                                    )
                                    .trim();

                                return TextSpan(
                                  children: [
                                    TextSpan(text: '$text '),
                                    if (arabicIndex.isNotEmpty)
                                      TextSpan(
                                        text: '﴿$arabicIndex﴾ ',
                                        style: TextStyle(
                                          color: Colors.amber[700],
                                          fontSize: 24 * _factor,
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                        : Text(
                            widget.content,
                            textAlign: TextAlign.center,
                            style:
                                (widget.isQuran
                                ? GoogleFonts.scheherazadeNew
                                : GoogleFonts.notoNaskhArabic)(
                                  fontSize:
                                      (widget.isQuran ? 26 : 20) * _factor,
                                  height: widget.isQuran ? 1.8 : 2.2,
                                  color: _customBgColor != null
                                      ? (_customBgColor!.computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white)
                                      : null,
                                ),
                          ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 12,
                          color: primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      'لون البطاقة:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...[
                      null,
                      const Color(0xFFFDF5E6),
                      const Color(0xFFE0EEE0),
                      const Color(0xFFE6E6FA),
                      const Color(0xFF2C2C2C),
                    ].map(
                      (c) => GestureDetector(
                        onTap: () => setState(() => _customBgColor = c),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: c ?? Colors.grey[300],
                          child: _customBgColor == c
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.blue,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          setState(() => _factor = max(0.5, _factor - 0.1)),
                    ),
                    const Text(
                      ' Aa ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () =>
                          setState(() => _factor = min(3.0, _factor + 0.1)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalSearchDelegate extends SearchDelegate {
  final double fontSizeFactor;
  GlobalSearchDelegate({required this.fontSizeFactor});
  @override
  String get searchFieldLabel => 'ابحث في كل الأقسام...';
  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );
  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();
  Widget _buildSearchResults() {
    if (query.isEmpty)
      return const Center(child: Text('ابدأ الكتابة للبحث...'));
    final normalizedQuery = query.trim().normalizeArabic();
    final sections = DataManager.getSections();
    List<Map<String, dynamic>> results = [];
    sections.forEach((key, sec) {
      for (var it in DataManager.getItems(key)) {
        if (it['title'].toString().normalizeArabic().contains(
              normalizedQuery,
            ) ||
            it['content'].toString().normalizeArabic().contains(
              normalizedQuery,
            )) {
          results.add({
            'section': sec['title'],
            'title': it['title'],
            'content': it['content'],
          });
        }
      }
    });
    if (results.isEmpty)
      return const Center(child: Text('لا توجد نتائج مطابقة'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(
          results[i]['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${results[i]['section']} - ${results[i]['content']}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => ReaderPage(
                title: results[i]['title'],
                content: results[i]['content'],
                fontSizeFactor: fontSizeFactor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final VoidCallback onThemeToggled;
  final Color primaryColor;
  final ValueChanged<Color> onColorChanged;
  final double uiOpacity;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<String?> onBackgroundImageChanged;
  final ValueChanged<String?> onBase64BgChanged;
  final String? backgroundImagePath;
  final Color cardColor;
  final ValueChanged<Color> onCardColorChanged;
  final Map<String, bool> visibility;
  final int hijriAdjustment;
  final void Function(String, bool) onVisibilityChanged;
  final ValueChanged<int> onHijriAdjustmentChanged;

  const SettingsSection({
    super.key,
    required this.onThemeToggled,
    required this.primaryColor,
    required this.onColorChanged,
    required this.uiOpacity,
    required this.onOpacityChanged,
    required this.onBackgroundImageChanged,
    required this.onBase64BgChanged,
    required this.backgroundImagePath,
    required this.cardColor,
    required this.onCardColorChanged,
    required this.visibility,
    required this.hijriAdjustment,
    required this.onVisibilityChanged,
    required this.onHijriAdjustmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final comfortColors = [
      Colors.white,
      const Color(0xFFFDF5E6),
      const Color(0xFFF5F5DC),
      const Color(0xFFE0EEE0),
      const Color(0xFFE6E6FA),
      const Color(0xFF2C2C2C),
      Colors.black,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroup(context, 'التقويم الهجري', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تعديل التاريخ الهجري:',
                  style: TextStyle(fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () =>
                          onHijriAdjustmentChanged(hijriAdjustment - 1),
                    ),
                    Text(
                      '$hijriAdjustment',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () =>
                          onHijriAdjustmentChanged(hijriAdjustment + 1),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          _buildGroup(context, 'المظهر العام', [
            SwitchListTile(
              title: const Text('الوضع الليلي'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (v) => onThemeToggled(),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            const Text(
              'لون سمة التطبيق',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children:
                  [
                        const Color(0xFFD4AF37),
                        Colors.blueGrey,
                        Colors.teal,
                        Colors.brown,
                      ]
                      .map(
                        (c) => GestureDetector(
                          onTap: () => onColorChanged(c),
                          child: CircleAvatar(
                            backgroundColor: c,
                            radius: 18,
                            child: primaryColor.toARGB32() == c.toARGB32()
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ]),
          _buildGroup(context, 'تخصيص البطاقات', [
            const Text(
              'لون خلفية البطاقات (مريح للعين)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: comfortColors
                  .map(
                    (c) => GestureDetector(
                      onTap: () => onCardColorChanged(c),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 18,
                        child: cardColor.toARGB32() == c.toARGB32()
                            ? Icon(
                                Icons.check,
                                color: c.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 15),
            const Text(
              'مستوى الشفافية',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Slider(
              value: uiOpacity,
              min: 0.3,
              max: 1.0,
              onChanged: onOpacityChanged,
              activeColor: primaryColor,
            ),
          ]),
          _buildGroup(context, 'الوسائط', [
            ListTile(
              title: const Text('اختيار خلفية مخصصة'),
              trailing: const Icon(Icons.image_search),
              contentPadding: EdgeInsets.zero,
              onTap: () async {
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.gallery);
                if (img != null) onBackgroundImageChanged(img.path);
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'معرض الخلفيات المرفوعة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: _buildBgGallery(context, (img) {
                onBase64BgChanged(img);
              }),
            ),
          ]),
          _buildGroup(context, 'إعدادات ظهور الصفحة الرئيسية', [
            _visToggle('inspiration', 'إلهام اليوم'),
            _visToggle('day_dua', 'دعاء اليوم'),
            ...DataManager.getSections().entries.map(
              (e) => _visToggle(e.key, e.value['title'].toString()),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBgGallery(
    BuildContext context,
    ValueChanged<String> onSelected,
  ) {
    final gallery =
        (DataManager.getSettings()['bg_gallery'] as List<dynamic>? ?? []);
    if (gallery.isEmpty)
      return const Center(
        child: Text('المعرض فارغ', style: TextStyle(fontSize: 12)),
      );
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: gallery.length,
      itemBuilder: (context, index) {
        final img = gallery[index].toString();
        return GestureDetector(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('custom_bg_base64_selected', img);
            await prefs.remove('backgroundImage');
            onSelected(img);
          },
          child: Container(
            margin: const EdgeInsets.only(left: 10),
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: _buildImage(img, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _visToggle(String key, String title) => SwitchListTile(
    title: Text(title, style: const TextStyle(fontSize: 14)),
    value: visibility[key] ?? true,
    onChanged: (v) => onVisibilityChanged(key, v),
    dense: true,
  );
}

class TasbihSection extends StatefulWidget {
  const TasbihSection({super.key});
  @override
  State<TasbihSection> createState() => _TasbihSectionState();
}

class _TasbihSectionState extends State<TasbihSection> {
  int _counter = 0;
  String _currentDhikr = "سبحان الله";
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFDFBF7),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Text(
              _currentDhikr,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 50),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    setState(() => _counter++);
                    HapticFeedback.lightImpact();
                  },
                  child: Ink(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark ? const Color(0xFF222222) : Colors.white,
                          isDark ? Colors.black : const Color(0xFFF0F0F0),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$_counter',
                        style: GoogleFonts.notoSans(
                          fontSize: 70,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, size: 30),
                onPressed: () => setState(() => _counter = 0),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'تصفير',
              ),
              const SizedBox(width: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButton<String>(
                  value: _currentDhikr,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _currentDhikr = v);
                  },
                  items:
                      [
                            'سبحان الله',
                            'الحمد لله',
                            'لا إله إلا الله',
                            'الله أكبر',
                            'أستغفر الله',
                            'اللهم صل على محمد وآل محمد',
                          ]
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v,
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

class PrayerTimesSection extends StatefulWidget {
  const PrayerTimesSection({super.key});
  @override
  State<PrayerTimesSection> createState() => _PrayerTimesSectionState();
}

class _PrayerTimesSectionState extends State<PrayerTimesSection> {
  Map<String, DateTime>? _prayerTimes;
  Position? _currentPosition;
  bool _loading = true;
  final PrayerTimesService _prayerService = PrayerTimesService();
  final Map<String, bool> _enabledPrayers = {
    'fajr': true,
    'dhuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
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
    _loadSettings();
    _getLocationAndPrayers();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabledPrayers['fajr'] = prefs.getBool('adhan_fajr') ?? true;
      _enabledPrayers['dhuhr'] = prefs.getBool('adhan_dhuhr') ?? true;
      _enabledPrayers['asr'] = prefs.getBool('adhan_asr') ?? true;
      _enabledPrayers['maghrib'] = prefs.getBool('adhan_maghrib') ?? true;
      _enabledPrayers['isha'] = prefs.getBool('adhan_isha') ?? true;
      _manualAdjustments['fajr'] = prefs.getInt('adj_fajr') ?? 0;
      _manualAdjustments['dhuhr'] = prefs.getInt('adj_dhuhr') ?? 0;
      _manualAdjustments['asr'] = prefs.getInt('adj_asr') ?? 0;
      _manualAdjustments['maghrib'] = prefs.getInt('adj_maghrib') ?? 0;
      _manualAdjustments['isha'] = prefs.getInt('adj_isha') ?? 0;
      _selectedProvince = prefs.getString('prayer_city') ?? "بغداد";

      final lat = prefs.getDouble('gps_lat');
      final lon = prefs.getDouble('gps_lon');
      if (lat != null &&
          lon != null &&
          _selectedProvince == "الموقع الحالي (GPS)") {
        _currentPosition = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    });
  }

  Future<void> _getLocationAndPrayers() async {
    try {
      Position pos;
      if (_currentPosition != null) {
        pos = _currentPosition!;
      } else {
        final coords = iraqProvinces[_selectedProvince]!;
        pos = Position(
          latitude: coords[0],
          longitude: coords[1],
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      final pt = _prayerService.calculatePrayerTimes(pos);
      final db = DataManager.getDB();
      final todayStr = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (db != null &&
          db['settings'] != null &&
          db['settings']['adhan'] != null &&
          db['settings']['adhan']['manual_schedules'] != null) {
        final list = db['settings']['adhan']['manual_schedules'] as List;
        final manual = list.firstWhere(
          (s) => s['date'] == todayStr,
          orElse: () => null,
        );
        if (manual != null) {
          pt['fajr'] = _applyManualTime(pt['fajr']!, manual['fajr']);
          pt['dhuhr'] = _applyManualTime(pt['dhuhr']!, manual['dhuhr']);
          pt['asr'] = _applyManualTime(pt['asr']!, manual['asr']);
          pt['maghrib'] = _applyManualTime(pt['maghrib']!, manual['maghrib']);
          pt['isha'] = _applyManualTime(pt['isha']!, manual['isha']);
        }
      }
      setState(() {
        _prayerTimes = pt;
        _loading = false;
      });
      await _prayerService.scheduleAdhanNotifications(
        pos,
        _enabledPrayers,
        _manualAdjustments,
      );
    } catch (e) {
      debugPrint("Prayer times error: $e");
      setState(() => _loading = false);
    }
  }

  DateTime _applyManualTime(DateTime calc, String? man) {
    if (man == null || !man.contains(':')) return calc;
    try {
      final parts = man.split(':');
      return DateTime(
        calc.year,
        calc.month,
        calc.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (e) {
      return calc;
    }
  }

  Future<void> _useGPS() async {
    setState(() => _loading = true);
    final pos = await _prayerService.getCurrentLocation();
    if (pos != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('gps_lat', pos.latitude);
      await prefs.setDouble('gps_lon', pos.longitude);
      await prefs.setString('prayer_city', "الموقع الحالي (GPS)");
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        _selectedProvince = "الموقع الحالي (GPS)";
      });
      _getLocationAndPrayers();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء منح صلاحية الوصول للموقع')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                          if (v != "الموقع الحالي (GPS)") {
                            await prefs.remove('gps_lat');
                            await prefs.remove('gps_lon');
                          }
                          setState(() {
                            _selectedProvince = v;
                            if (v != "الموقع الحالي (GPS)")
                              _currentPosition = null;
                            _loading = true;
                          });
                          _getLocationAndPrayers();
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
                const Divider(),
                TextButton.icon(
                  onPressed: _useGPS,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _currentPosition == null
                        ? 'استخدام الموقع الحالي (GPS)'
                        : 'موقعك محدد حالياً عبر GPS',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPrayerCard('الفجر', _prayerTimes?['fajr'], 'fajr'),
          _buildPrayerCard('الظهر', _prayerTimes?['dhuhr'], 'dhuhr'),
          _buildPrayerCard('العصر', _prayerTimes?['asr'], 'asr'),
          _buildPrayerCard('المغرب', _prayerTimes?['maghrib'], 'maghrib'),
          _buildPrayerCard('العشاء', _prayerTimes?['isha'], 'isha'),
          const SizedBox(height: 30),
          const Divider(),
          const Text(
            'إعدادات الأذان والتنبيهات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          ..._enabledPrayers.keys.map(
            (k) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                title: Text(
                  'تفعيل أذان ${{'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء'}[k]}',
                ),
                value: _enabledPrayers[k] ?? true,
                onChanged: (v) async {
                  setState(() => _enabledPrayers[k] = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('adhan_$k', v);
                  _getLocationAndPrayers();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(String label, DateTime? originalTime, String key) {
    if (originalTime == null) return const SizedBox();
    final adjTime = originalTime.add(
      Duration(minutes: _manualAdjustments[key] ?? 0),
    );
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
            final diff = DateTime(
              originalTime.year,
              originalTime.month,
              originalTime.day,
              picked.hour,
              picked.minute,
            ).difference(originalTime).inMinutes;
            setState(() {
              _manualAdjustments[key] = diff;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('adj_$key', diff);
            _getLocationAndPrayers();
          }
        },
      ),
    );
  }
}
