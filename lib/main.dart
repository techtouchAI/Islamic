import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'dart:math';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:io';

import 'data/data_manager.dart';
import 'data/daily_duas.dart';

class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const double step = 40;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        final path = Path();
        path.moveTo(x + step / 2, y);
        path.lineTo(x + step, y + step / 2);
        path.lineTo(x + step / 2, y + step);
        path.lineTo(x, y + step / 2);
        path.close();

        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(x + step / 2, y + step / 2), step / 4, paint);
      }
    }
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

Widget _buildImage(String? path, {double? height, BoxFit fit = BoxFit.contain}) {
  if (path == null || path.isEmpty) return const SizedBox();

  if (path.startsWith('data:image')) {
     try {
       final bytes = Uri.parse(path).data!.contentAsBytes();
       return Image.memory(Uint8List.fromList(bytes), height: height, fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
     } catch (e) { return const Icon(Icons.broken_image); }
  }

  if (path.startsWith('http')) {
    return Image.network(path, height: height, fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.error));
  }
  return Image.asset(path, height: height, fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported));
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

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

      tz_data.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);

      await _loadSettings();

      DataManager.syncCloudData(); // Async background sync
    } catch (e) {
      debugPrint("Initialization Error: $e");
    } finally {
      if (mounted) setState(() => _isInitialized = true);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dbSettings = DataManager.getSettings();

    if (dbSettings.isEmpty) {
       debugPrint("Warning: Config database is empty or failed to load.");
    }

    // Default color from JSON if not in prefs
    int defaultPrimary = int.tryParse(dbSettings['primary_color'] ?? '0xFFD4AF37') ?? 0xFFD4AF37;
    int defaultCard = int.tryParse(dbSettings['card_color'] ?? '0xFFFFFFFF') ?? 0xFFFFFFFF;

    setState(() {
      _themeMode = (prefs.getString('theme') ?? 'light') == 'light' ? ThemeMode.light : ThemeMode.dark;
      _fontSizeFactor = prefs.getDouble('fontSize') ?? 1.0;
      _primaryColor = Color(prefs.getInt('primaryColor') ?? defaultPrimary);
      _uiOpacity = prefs.getDouble('uiOpacity') ?? (dbSettings['ui_opacity']?.toDouble() ?? 1.0);
      _backgroundImagePath = prefs.getString('backgroundImage');
      _selectedBase64Bg = prefs.getString('custom_bg_base64_selected');
      _cardColor = Color(prefs.getInt('cardColor') ?? defaultCard);

      final sections = DataManager.getSections();
      _homeVisibility = {};
      sections.forEach((key, value) {
        _homeVisibility[key] = prefs.getBool('vis_$key') ?? (value['visible_home'] ?? true);
      });
      _homeVisibility['inspiration'] = prefs.getBool('vis_inspiration') ?? (dbSettings['show_inspiration'] ?? true);
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
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
        textTheme: GoogleFonts.notoKufiArabicTextTheme(ThemeData.dark().textTheme),
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
          title: Text(_getAppBarTitle(_currentSection), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor?.withValues(alpha: widget.uiOpacity),
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
                  delegate: GlobalSearchDelegate(fontSizeFactor: widget.fontSizeFactor),
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
            if (widget.backgroundImagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(widget.backgroundImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            if (widget.backgroundImagePath == null)
              Positioned.fill(
                child: _buildImage(widget.selectedBase64Bg ?? settings['custom_bg_base64']?.toString() ?? settings['bg_image']?.toString(), fit: BoxFit.cover),
              ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: CustomPaint(painter: IslamicPatternPainter(color: Theme.of(context).colorScheme.primary)),
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
        );
      case 'about':
        return const AboutSection(key: ValueKey('about'));
      case 'tasbih':
        return const TasbihSection(key: ValueKey('tasbih'));
      case 'prayer_times':
        return const PrayerTimesSection(key: ValueKey('prayer_times'));
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

  const AppDrawer({super.key, required this.currentSection, required this.onNavigate});

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
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildImage(settings['custom_logo_base64']?.toString() ?? settings['logo_image']?.toString(), height: 60),
                  const SizedBox(height: 10),
                  const Text('تطبيق الذاكرين', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(about['developer_name']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(context, 'home', 'الرئيسية', Icons.home),
                _buildItem(context, 'prayer_times', 'أوقات الصلاة', Icons.access_time),
                _buildItem(context, 'tasbih', 'المسبحة الإلكترونية', Icons.vibration),
                ...sections.entries.map((e) {
                   return _buildItem(context, e.key, e.value['title'], _getIcon(e.value['icon']));
                }),
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

  IconData _getIcon(String? name) {
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
    };
    return iconMap[name] ?? Icons.star;
  }

  Widget _buildItem(BuildContext context, String id, String title, IconData icon) {
    final bool active = currentSection == id;
    return ListTile(
      leading: Icon(icon, color: active ? Theme.of(context).colorScheme.primary : null),
      title: Text(title, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
      selected: active,
      selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      onTap: () => onNavigate(id),
    );
  }
}

class HomeSection extends StatefulWidget {
  final double fontSizeFactor;
  final double uiOpacity;
  final Color cardColor;
  final Map<String, bool> visibility;
  const HomeSection({super.key, required this.fontSizeFactor, required this.uiOpacity, required this.cardColor, required this.visibility});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  late Map<String, dynamic> items;
  Map<String, dynamic>? _inspirationDua;
  Map<String, dynamic>? _dayDua;

  @override
  void initState() {
    super.initState();
    _refreshItems();
    _loadDailyDua();
  }

  void _refreshItems() {
    final random = Random();
    final sections = DataManager.getSections();
    items = {};
    sections.forEach((key, value) {
       if (widget.visibility[key] ?? true) {
         items[value['title']] = _safeGet(DataManager.getItems(key), random);
       }
    });
  }

  void _loadDailyDua() {
    final now = DateTime.now();

    // 1. Load Inspiration of the day (Rotating snippet)
    const dayOfYearStr = 'D';
    final dayOfYear = int.parse(intl.DateFormat(dayOfYearStr).format(now));
    const source = DailyDuas.shortDuas;
    _inspirationDua = source[dayOfYear % source.length];

    // 2. Load Day Dua from content.json (e.g. Dua for Friday)
    final db = DataManager.getDB();
    final dayName = intl.DateFormat('EEEE', 'en_US').format(now); // Friday, Saturday...
    if (db != null && db['daily_duas'] != null && db['daily_duas'][dayName] != null) {
       _dayDua = db['daily_duas'][dayName];
    }

    setState(() {});
  }

  dynamic _safeGet(List list, Random r) {
    if (list.isEmpty) return {'title': 'قريباً', 'content': ''};
    return list[r.nextInt(list.length)];
  }

  Widget _buildSpecialCard(BuildContext context, String tag, Map<String, dynamic> data, Color textColor, IconData icon) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ReaderPage(
        title: data['title'].toString(),
        content: data['content'].toString(),
        fontSizeFactor: widget.fontSizeFactor,
      ))),
      child: Card(
        elevation: 5,
        color: widget.cardColor.withValues(alpha: widget.uiOpacity),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(tag, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data['content'].toString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoNaskhArabic(fontSize: 16, height: 1.8, color: textColor),
              ),
              const SizedBox(height: 10),
              Text('— ${data["title"]} —', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6))),
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
            Card(
              elevation: 10,
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: widget.uiOpacity)
                : Colors.black.withValues(alpha: widget.uiOpacity),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.5),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: Column(
                  children: [
                    _ClockWidget(color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(intl.DateFormat('EEEE, d MMMM yyyy', 'ar_SA').format(now), style: TextStyle(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_dayDua != null)
              _buildSpecialCard(context, 'دعاء اليوم', _dayDua!, textColor, Icons.calendar_today),
            const SizedBox(height: 15),
            if (_inspirationDua != null && (widget.visibility['inspiration'] ?? true))
              _buildSpecialCard(context, 'إلهام اليوم', _inspirationDua!, textColor, Icons.auto_awesome),
            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerRight,
              child: Text('مقتطفات إيمانية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87)),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items.entries.map((e) {
                return RepaintBoundary(
                  child: _HomeSmallCard(
                    tag: e.key,
                    title: e.value['title'].toString(),
                    uiOpacity: widget.uiOpacity,
                    cardColor: widget.cardColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ReaderPage(
                            title: e.value['title'].toString(),
                            content: e.value['content'].toString(),
                            fontSizeFactor: widget.fontSizeFactor,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
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
  const _HomeSmallCard({required this.tag, required this.title, required this.uiOpacity, required this.cardColor, required this.onTap});

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
          color: cardColor.withValues(alpha: uiOpacity),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10, bottom: -10,
              child: Opacity(
                opacity: 0.1,
                child: Icon(Icons.star, size: 80, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tag, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor, height: 1.2)),
                ],
              ),
            ),
          ],
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
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    _timeNotifier.dispose();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = intl.DateFormat('hh:mm:ss a', 'en_US').format(now);
    _timeNotifier.value = formattedTime.replaceFirst('AM', 'ص').replaceFirst('PM', 'م');
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<String>(
        valueListenable: _timeNotifier,
        builder: (context, value, child) {
          return FittedBox(
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
          );
        },
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
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(getMaterialIcon(about['developer_icon']?.toString() ?? 'person'), size: 60, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(about['developer_name']?.toString() ?? 'المطور', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  onPressed: () => launchUrl(Uri.parse(about['developer_page'].toString())),
                  icon: const Icon(Icons.link),
                  label: const Text('زيارة الموقع الشخصي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DynamicListSection extends StatelessWidget {
  final String title;
  final String sectionKey;
  final double fontSizeFactor;
  final double uiOpacity;
  const DynamicListSection({super.key, required this.title, required this.sectionKey, required this.fontSizeFactor, required this.uiOpacity});

  @override
  Widget build(BuildContext context) {
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
                  itemBuilder: (context, index) {
                    // Note: Here we'd ideally pass the cardColor from settings.
                    // For now, using the uiOpacity.
                    return Card(
                      color: Theme.of(context).cardColor.withValues(alpha: uiOpacity),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        title: Text(data[index]['title'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(data[index]['content'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.amiri(fontSize: 16)),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ReaderPage(title: data[index]['title'].toString(), content: data[index]['content'].toString(), fontSizeFactor: fontSizeFactor))),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ReaderPage extends StatefulWidget {
  final String title, content;
  final double fontSizeFactor;
  const ReaderPage({super.key, required this.title, required this.content, required this.fontSizeFactor});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late double _factor;
  Color? _customBgColor;

  @override
  void initState() {
    super.initState();
    _factor = widget.fontSizeFactor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.content_copy), onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.content));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ النص')));
          }),
          IconButton(icon: const Icon(Icons.share), onPressed: () => Share.share(widget.content)),
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
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                  borderRadius: BorderRadius.circular(25),
                  color: _customBgColor ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 2)
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "بسم الله الرحمن الرحيم",
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => Icon(Icons.star, size: 12, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      widget.content,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 20 * _factor,
                        height: 2.2,
                        color: _customBgColor != null
                          ? (_customBgColor!.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                          : null,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => Icon(Icons.star, size: 12, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5))),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('لون البطاقة:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...[
                      null,
                      const Color(0xFFFDF5E6),
                      const Color(0xFFE0EEE0),
                      const Color(0xFFE6E6FA),
                      const Color(0xFF2C2C2C),
                    ].map((c) => GestureDetector(
                      onTap: () => setState(() => _customBgColor = c),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: c ?? Colors.grey[300],
                        child: _customBgColor == c ? const Icon(Icons.check, size: 14, color: Colors.blue) : null,
                      ),
                    )),
                  ],
                ),
                const Divider(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _factor = max(0.5, _factor - 0.1))),
                    const Text(' Aa ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _factor = min(3.0, _factor + 0.1))),
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
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // Remove Tashkeel
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('ابدأ الكتابة للبحث...'));
    }

    final normalizedQuery = _normalize(query.trim());
    final sections = DataManager.getSections();
    List<Map<String, dynamic>> results = [];

    sections.forEach((key, sec) {
      final items = DataManager.getItems(key);
      for (var it in items) {
        final normalizedTitle = _normalize(it['title'].toString());
        final normalizedContent = _normalize(it['content'].toString());

        if (normalizedTitle.contains(normalizedQuery) || normalizedContent.contains(normalizedQuery)) {
          results.add({
            'section': sec['title'],
            'title': it['title'],
            'content': it['content'],
          });
        }
      }
    });

    if (results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج مطابقة'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text(results[i]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${results[i]['section']} - ${results[i]['content']}', maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => ReaderPage(
              title: results[i]['title'],
              content: results[i]['content'],
              fontSizeFactor: fontSizeFactor,
            )));
          },
        );
      },
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
  final void Function(String, bool) onVisibilityChanged;

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
    required this.onVisibilityChanged,
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
          _buildGroup(context, 'المظهر العام', [
            SwitchListTile(
              title: const Text('الوضع الليلي'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (v) => onThemeToggled(),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            const Text('لون سمة التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [const Color(0xFFD4AF37), Colors.blueGrey, Colors.teal, Colors.brown].map((c) => GestureDetector(
                onTap: () => onColorChanged(c),
                child: CircleAvatar(
                  backgroundColor: c,
                  radius: 18,
                  child: primaryColor.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white, size: 16) : null
                ),
              )).toList(),
            ),
          ]),

          _buildGroup(context, 'تخصيص البطاقات', [
            const Text('لون خلفية البطاقات (مريح للعين)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: comfortColors.map((c) => GestureDetector(
                onTap: () => onCardColorChanged(c),
                child: CircleAvatar(
                  backgroundColor: c,
                  radius: 18,
                  child: cardColor.toARGB32() == c.toARGB32() ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16) : null,
                ),
              )).toList(),
            ),
            const SizedBox(height: 15),
            const Text('مستوى الشفافية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Slider(value: uiOpacity, min: 0.3, max: 1.0, onChanged: onOpacityChanged, activeColor: primaryColor),
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
            const Text('معرض الخلفيات المرفوعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            _visToggle('quran', 'القرآن الكريم'),
            _visToggle('duas', 'الأدعية'),
            _visToggle('visits', 'الزيارات'),
            _visToggle('tafsir', 'التفسير'),
            _visToggle('dreams', 'تفسير الأحلام'),
            _visToggle('stories', 'قصص الأنبياء'),
            _visToggle('imam_ali', 'موسوعة الإمام علي (ع)'),
          ]),
        ],
      ),
    );
  }

  Widget _buildBgGallery(BuildContext context, ValueChanged<String> onSelected) {
    final settings = DataManager.getSettings();
    final List<dynamic> gallery = settings['bg_gallery'] ?? [];

    if (gallery.isEmpty) return const Center(child: Text('المعرض فارغ', style: TextStyle(fontSize: 12)));

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: gallery.length,
      itemBuilder: (context, index) {
        final img = gallery[index].toString();
        return GestureDetector(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('custom_bg_base64_selected', img);
            await prefs.remove('backgroundImage'); // Clear file path if set
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

  Widget _buildGroup(BuildContext context, String title, List<Widget> children) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
          Text(title, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _visToggle(String key, String title) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: visibility[key] ?? true,
      onChanged: (v) => onVisibilityChanged(key, v),
      dense: true,
    );
  }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
            child: Text(
              _currentDhikr,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: () {
              setState(() => _counter++);
              HapticFeedback.lightImpact();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 8),
                    boxShadow: [
                      BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
                    ],
                  ),
                ),
                Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  child: Center(
                    child: Text(
                      '$_counter',
                      style: GoogleFonts.notoSans(fontSize: 70, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
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
                onPressed: () => setState(() => _counter = 0),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'تصفير',
              ),
              const SizedBox(width: 30),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                ),
                child: DropdownButton<String>(
                  value: _currentDhikr,
                  underline: const SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                  onChanged: (String? newValue) {
                    if (newValue != null) setState(() => _currentDhikr = newValue);
                  },
                  items: <String>['سبحان الله', 'الحمد لله', 'لا إله إلا الله', 'الله أكبر', 'أستغفر الله', 'اللهم صل على محمد وآل محمد']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
                    }).toList(),
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
  PrayerTimes? _prayerTimes;
  Position? _currentPosition;
  bool _loading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, bool> _enabledPrayers = {
    'fajr': true, 'dhuhr': true, 'asr': true, 'maghrib': true, 'isha': true
  };
  Map<String, int> _manualAdjustments = {
    'fajr': 0, 'dhuhr': 0, 'asr': 0, 'maghrib': 0, 'isha': 0
  };
  String _selectedProvince = "بغداد";
  final Map<String, List<double>> _iraqProvinces = {
    "بغداد": [33.3128, 44.3615],
    "البصرة": [30.5081, 47.7835],
    "النجف الأشرف": [32.0259, 44.3462],
    "كربلاء المقدسة": [32.6160, 44.0248],
    "أربيل": [36.1901, 44.0094],
    "الموصل": [36.3489, 43.1577],
    "كركوك": [35.4681, 44.3922],
    "السليمانية": [35.5561, 45.4333],
    "العمارة": [31.8453, 47.1420],
    "الناصرية": [31.0577, 46.2573],
    "الكوت": [32.5020, 45.8202],
    "الحلة": [32.4810, 44.4305],
    "الديوانية": [31.9904, 44.9258],
    "بعقوبة": [33.7431, 44.6361],
    "الرمادي": [33.4219, 43.3032],
    "تكريت": [34.6074, 43.6766],
    "السماوة": [31.3120, 45.2810],
    "دهوك": [36.8679, 42.9431],
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getLocationAndPrayers();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabledPrayers.forEach((k, v) {
        _enabledPrayers[k] = prefs.getBool('adhan_$k') ?? true;
        _manualAdjustments[k] = prefs.getInt('adj_$k') ?? 0;
      });
    });
  }

  Future<void> _getLocationAndPrayers() async {
    try {
      Coordinates coordinates;

      if (_currentPosition != null) {
        coordinates = Coordinates(_currentPosition!.latitude, _currentPosition!.longitude);
      } else {
        final coords = _iraqProvinces[_selectedProvince]!;
        coordinates = Coordinates(coords[0], coords[1]);
      }

      // Shia Tehran/Jafari Method - Iraq Official Shia Timing
      final params = CalculationMethodParameters.tehran();
      params.madhab = Madhab.shafi;

      final pt = PrayerTimes(
        coordinates: coordinates,
        date: DateTime.now(),
        calculationParameters: params,
        precision: true
      );

      setState(() {
        _prayerTimes = pt;
        _loading = false;
      });
      _scheduleNotifications();
    } catch (e) {
      debugPrint("Prayer times error: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _useGPS() async {
    setState(() => _loading = true);
    try {
      if (await Permission.location.request().isGranted) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentPosition = pos;
        });
        _getLocationAndPrayers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء منح صلاحية الوصول للموقع')));
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("GPS Error: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _scheduleNotifications() async {
    if (_prayerTimes == null) return;
    await flutterLocalNotificationsPlugin.cancelAll();

    if (await Permission.notification.request().isDenied) return;

    _schedulePrayer('fajr', 'صلاة الفجر', _prayerTimes!.fajr, 1);
    _schedulePrayer('dhuhr', 'صلاة الظهر', _prayerTimes!.dhuhr, 2);
    _schedulePrayer('asr', 'صلاة العصر', _prayerTimes!.asr, 3);
    _schedulePrayer('maghrib', 'صلاة المغرب', _prayerTimes!.maghrib, 4);
    _schedulePrayer('isha', 'صلاة العشاء', _prayerTimes!.isha, 5);
  }

  Future<void> _schedulePrayer(String key, String title, DateTime time, int id) async {
     if (!(_enabledPrayers[key] ?? true)) return;

     final adjTime = time.add(Duration(minutes: _manualAdjustments[key] ?? 0));
     if (adjTime.isBefore(DateTime.now())) return;

     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'adhan_channel', 'الأذان والتنبيهات',
        importance: Importance.max, priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('adhan'),
        playSound: true,
     );

     await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: 'حان وقت $title',
        body: 'حي على الصلاة',
        scheduledDate: tz.TZDateTime.from(adjTime, tz.local),
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
     );
  }

  void _checkAdhan() {
     Timer.periodic(const Duration(minutes: 1), (timer) {
        if (_prayerTimes == null) return;
        final now = DateTime.now();
        _checkTime('fajr', _prayerTimes!.fajr, now);
        _checkTime('dhuhr', _prayerTimes!.dhuhr, now);
        _checkTime('asr', _prayerTimes!.asr, now);
        _checkTime('maghrib', _prayerTimes!.maghrib, now);
        _checkTime('isha', _prayerTimes!.isha, now);
     });
  }

  void _checkTime(String key, DateTime? time, DateTime now) {
     if (time == null || !(_enabledPrayers[key] ?? false)) return;
     final adjTime = time.add(Duration(minutes: _manualAdjustments[key] ?? 0));
     if (now.hour == adjTime.hour && now.minute == adjTime.minute) {
        _playAdhan();
     }
  }

  Future<void> _playAdhan() async {
    await _audioPlayer.play(AssetSource('audio/adhan.mp3'));
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on),
                    const SizedBox(width: 10),
                    const Text('المحافظة:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _selectedProvince,
                      underline: const SizedBox(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                             _selectedProvince = v;
                             _currentPosition = null;
                             _loading = true;
                          });
                          _getLocationAndPrayers();
                        }
                      },
                      items: _iraqProvinces.keys.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    ),
                  ],
                ),
                const Divider(),
                TextButton.icon(
                  onPressed: _useGPS,
                  icon: const Icon(Icons.my_location),
                  label: Text(_currentPosition == null ? 'استخدام الموقع الحالي (GPS)' : 'موقعك محدد حالياً عبر GPS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPrayerCard('الفجر', _prayerTimes?.fajr, 'fajr'),
          _buildPrayerCard('الظهر', _prayerTimes?.dhuhr, 'dhuhr'),
          _buildPrayerCard('العصر', _prayerTimes?.asr, 'asr'),
          _buildPrayerCard('المغرب', _prayerTimes?.maghrib, 'maghrib'),
          _buildPrayerCard('العشاء', _prayerTimes?.isha, 'isha'),
          const SizedBox(height: 30),
          const Divider(),
          const Text('إعدادات الأذان والتنبيهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ..._enabledPrayers.keys.map((k) => _buildSettingsRow(k)).toList(),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(String label, DateTime? originalTime, String key) {
    if (originalTime == null) return const SizedBox();
    final adjTime = originalTime.add(Duration(minutes: _manualAdjustments[key] ?? 0));
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Theme.of(context).colorScheme.primary)
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('اضغط لتعديل الوقت يدوياً', style: TextStyle(fontSize: 10)),
        trailing: Text(
          intl.DateFormat('hh:mm a').format(adjTime),
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)
        ),
        onTap: () async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(adjTime),
          );
          if (picked != null) {
            final now = DateTime.now();
            final pickedDT = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
            final diff = pickedDT.difference(originalTime).inMinutes;
            setState(() {
               _manualAdjustments[key] = diff;
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('adj_$key', diff);
            _scheduleNotifications();
          }
        },
      ),
    );
  }

  Widget _buildSettingsRow(String key) {
     final names = {'fajr': 'الفجر', 'dhuhr': 'الظهر', 'asr': 'العصر', 'maghrib': 'المغرب', 'isha': 'العشاء'};
     return Card(
       margin: const EdgeInsets.only(bottom: 10),
       child: Column(
         children: [
           SwitchListTile(
             title: Text('تفعيل أذان ${names[key]}'),
             value: _enabledPrayers[key] ?? true,
             onChanged: (v) async {
               setState(() => _enabledPrayers[key] = v);
               final prefs = await SharedPreferences.getInstance();
               await prefs.setBool('adhan_$key', v);
               _scheduleNotifications();
             },
           ),
         ],
       ),
     );
  }
}
