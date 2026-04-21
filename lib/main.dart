import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
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
  if (path.startsWith('http')) {
    return Image.network(path, height: height, fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.error));
  }
  return Image.asset(path, height: height, fit: fit, errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported));
}

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('ar_SA', null);
    HijriCalendar.setLocal('ar');
    await DataManager.loadContent();
    runApp(const AlDhakereenApp());
  }, (error, stackTrace) {
    debugPrint('Global error: $error');
  });
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
  Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      _cardColor = Color(prefs.getInt('cardColor') ?? defaultCard);
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
        onBackgroundImageChanged: (path) {
          setState(() => _backgroundImagePath = path);
          if (path != null) _saveSetting('backgroundImage', path);
        },
        cardColor: _cardColor,
        onCardColorChanged: (c) {
          setState(() => _cardColor = c);
          _saveSetting('cardColor', c.toARGB32());
        },
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final double fontSizeFactor;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onThemeToggled;
  final Color primaryColor;
  final ValueChanged<Color> onColorChanged;
  final double uiOpacity;
  final ValueChanged<double> onOpacityChanged;
  final String? backgroundImagePath;
  final ValueChanged<String?> onBackgroundImageChanged;
  final Color cardColor;
  final ValueChanged<Color> onCardColorChanged;

  const MainScaffold({
    super.key,
    required this.fontSizeFactor,
    required this.onFontSizeChanged,
    required this.onThemeToggled,
    required this.primaryColor,
    required this.onColorChanged,
    required this.uiOpacity,
    required this.onOpacityChanged,
    required this.backgroundImagePath,
    required this.onBackgroundImageChanged,
    required this.cardColor,
    required this.onCardColorChanged,
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
          title: const Text('الذاكرين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
            if (isSubPage)
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: _onBack,
                tooltip: 'رجوع',
              ),
            if (!isSubPage) const SizedBox(width: 48),
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
                child: _buildImage(settings['bg_image']?.toString(), fit: BoxFit.cover),
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
          backgroundImagePath: widget.backgroundImagePath,
          cardColor: widget.cardColor,
          onCardColorChanged: widget.onCardColorChanged,
        );
      case 'about':
        return const AboutSection(key: ValueKey('about'));
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
                  _buildImage(settings['logo_image']?.toString(), height: 50),
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
  const HomeSection({super.key, required this.fontSizeFactor, required this.uiOpacity, required this.cardColor});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  late Map<String, dynamic> items;
  Map<String, dynamic>? _dailyDua;

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
       items[value['title']] = _safeGet(DataManager.getItems(key), random);
    });
  }

  void _loadDailyDua() {
    // Selection based on the day of the year
    final now = DateTime.now();
    const dayOfYearStr = 'D';
    final dayOfYear = int.parse(intl.DateFormat(dayOfYearStr).format(now));

    const source = DailyDuas.shortDuas;

    setState(() {
      _dailyDua = source[dayOfYear % source.length];
    });
  }

  dynamic _safeGet(List list, Random r) {
    if (list.isEmpty) return {'title': 'قريباً', 'content': ''};
    return list[r.nextInt(list.length)];
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
              color: Colors.black.withValues(alpha: widget.uiOpacity),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: Column(
                  children: [
                    const _ClockWidget(),
                    const SizedBox(height: 8),
                    Text('${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(intl.DateFormat('EEEE, d MMMM yyyy', 'ar_SA').format(now), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_dailyDua != null)
              Card(
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
                          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('إلهام اليوم', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _dailyDua!['content'].toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(fontSize: 18, height: 1.6, color: textColor),
                      ),
                      const SizedBox(height: 10),
                      Text('— ${_dailyDua!['title']} —', style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
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
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: (MediaQuery.of(context).size.width - 48) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor.withValues(alpha: uiOpacity),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tag, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  const _ClockWidget();
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
              style: const TextStyle(
                color: Color(0xFFD4AF37),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'ابحث في $title...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor.withValues(alpha: uiOpacity),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ),
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
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                ),
                child: Column(
                  children: [
                    Icon(Icons.star_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      widget.content,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(fontSize: 22 * _factor, height: 1.8),
                    ),
                    const SizedBox(height: 12),
                    Icon(Icons.star_outline, color: Theme.of(context).colorScheme.primary),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() => _factor = max(0.5, _factor - 0.1))),
                const Text(' Aa ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _factor = min(3.0, _factor + 0.1))),
              ],
            ),
          ),
        ],
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
  final String? backgroundImagePath;
  final Color cardColor;
  final ValueChanged<Color> onCardColorChanged;

  const SettingsSection({
    super.key,
    required this.onThemeToggled,
    required this.primaryColor,
    required this.onColorChanged,
    required this.uiOpacity,
    required this.onOpacityChanged,
    required this.onBackgroundImageChanged,
    required this.backgroundImagePath,
    required this.cardColor,
    required this.onCardColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final comfortColors = [
      Colors.white,
      const Color(0xFFFDF5E6), // Old Lace
      const Color(0xFFF5F5DC), // Beige
      const Color(0xFFE0EEE0), // Honeydew
      const Color(0xFFE6E6FA), // Lavender
      const Color(0xFF2C2C2C), // Dark Grey
      Colors.black,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('الوضع الليلي'),
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (v) => onThemeToggled(),
        ),
        const Divider(),
        const Text('لون ثمة التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [const Color(0xFFD4AF37), Colors.blueGrey, Colors.teal, Colors.brown].map((c) => GestureDetector(
            onTap: () => onColorChanged(c),
            child: CircleAvatar(backgroundColor: c, radius: 20, child: primaryColor.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white) : null),
          )).toList(),
        ),
        const Divider(),
        const Text('لون خلفية البطاقات (مريح للعين)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: comfortColors.map((c) => GestureDetector(
            onTap: () => onCardColorChanged(c),
            child: CircleAvatar(
              backgroundColor: c,
              radius: 20,
              child: cardColor.toARGB32() == c.toARGB32() ? Icon(Icons.check, color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white) : null,
            ),
          )).toList(),
        ),
        const Divider(),
        const Text('الشفافية', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(value: uiOpacity, min: 0.3, max: 1.0, onChanged: onOpacityChanged),
        const Divider(),
        ListTile(
          title: const Text('تغيير خلفية التطبيق'),
          trailing: const Icon(Icons.image),
          onTap: () async {
             final picker = ImagePicker();
             final img = await picker.pickImage(source: ImageSource.gallery);
             if (img != null) onBackgroundImageChanged(img.path);
          },
        ),
      ],
    );
  }
}
