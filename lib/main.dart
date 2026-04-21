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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_SA', null);
  await DataManager.loadContent();
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = (prefs.getString('theme') ?? 'light') == 'light' ? ThemeMode.light : ThemeMode.dark;
      _fontSizeFactor = prefs.getDouble('fontSize') ?? 1.0;
      _primaryColor = Color(prefs.getInt('primaryColor') ?? 0xFFD4AF37);
      _uiOpacity = prefs.getDouble('uiOpacity') ?? 1.0;
      _backgroundImagePath = prefs.getString('backgroundImage');
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
            if (widget.backgroundImagePath == null && settings['bg_image'] != null)
              Positioned.fill(
                child: Image.asset(
                  settings['bg_image'].toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox(),
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
        return HomeSection(key: const ValueKey('home'), fontSizeFactor: widget.fontSizeFactor, uiOpacity: widget.uiOpacity);
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
    switch (key) {
      case 'quran': return 'القرآن الكريم';
      case 'duas': return 'الأدعية';
      case 'visits': return 'الزيارات';
      case 'tafsir': return 'التفسير';
      case 'dreams': return 'تفسير الأحلام';
      case 'stories': return 'قصص الأنبياء';
      case 'imam_ali': return 'موسوعة الإمام علي (ع)';
      default: return 'المحتوى';
    }
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
                  if (settings['logo_image'] != null)
                     Image.asset(settings['logo_image'].toString(), height: 50, errorBuilder: (c,e,s) => const Icon(Icons.mosque, size: 50, color: Colors.white)),
                  if (settings['logo_image'] == null)
                     const Icon(Icons.mosque, size: 50, color: Colors.white),
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
                _buildItem(context, 'quran', 'القرآن الكريم', Icons.menu_book),
                _buildItem(context, 'duas', 'الأدعية', Icons.auto_stories),
                _buildItem(context, 'visits', 'الزيارات', Icons.place),
                _buildItem(context, 'tafsir', 'التفسير', Icons.translate),
                _buildItem(context, 'dreams', 'تفسير الأحلام', Icons.bedtime),
                _buildItem(context, 'stories', 'قصص الأنبياء', Icons.history_edu),
                _buildItem(context, 'imam_ali', 'موسوعة الإمام علي (ع)', Icons.shield),
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
  const HomeSection({super.key, required this.fontSizeFactor, required this.uiOpacity});

  @override
  State<HomeSection> createState() => _HomeSectionState();
}

class _HomeSectionState extends State<HomeSection> {
  late Map<String, dynamic> items;

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  void _refreshItems() {
    final random = Random();
    items = {
      'القرآن': _safeGet(DataManager.getItems('quran'), random),
      'الأدعية': _safeGet(DataManager.getItems('duas'), random),
      'الزيارات': _safeGet(DataManager.getItems('visits'), random),
      'التفسير': _safeGet(DataManager.getItems('tafsir'), random),
      'الأحلام': _safeGet(DataManager.getItems('dreams'), random),
      'القصص': _safeGet(DataManager.getItems('stories'), random),
      'الإمام علي (ع)': _safeGet(DataManager.getItems('imam_ali'), random),
    };
  }

  dynamic _safeGet(List list, Random r) {
    if (list.isEmpty) return {'title': 'قريباً', 'content': ''};
    return list[r.nextInt(list.length)];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hijri = HijriCalendar.now();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Card(
            elevation: 10,
            color: Colors.black.withValues(alpha: widget.uiOpacity),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              child: Column(
                children: [
                  const _ClockWidget(),
                  const SizedBox(height: 8),
                  Text('${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(intl.DateFormat('EEEE, d MMMM yyyy', 'ar_SA').format(now), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Text('مقتطفات إيمانية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.entries.map((e) => _HomeSmallCard(tag: e.key, title: e.value['title'].toString(), uiOpacity: widget.uiOpacity)).toList(),
          ),
        ],
      ),
    );
  }
}

class _HomeSmallCard extends StatelessWidget {
  final String tag, title;
  final double uiOpacity;
  const _HomeSmallCard({required this.tag, required this.title, required this.uiOpacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: uiOpacity),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tag, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
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
  String _timeString = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = intl.DateFormat('hh:mm:ss a', 'en_US').format(now);
    if (mounted) {
      setState(() {
        _timeString = formattedTime.replaceFirst('AM', 'ص').replaceFirst('PM', 'م');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        _timeString,
        maxLines: 1,
        style: const TextStyle(
          color: Color(0xFFD4AF37),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(about['developer_name']?.toString() ?? 'المطور', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(about['app_info']?.toString() ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            if (about['developer_page'] != null)
              ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse(about['developer_page'].toString())),
                icon: const Icon(Icons.link),
                label: const Text('زيارة الموقع الشخصي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
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
                  itemBuilder: (context, index) => Card(
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
                  ),
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

  const SettingsSection({
    super.key,
    required this.onThemeToggled,
    required this.primaryColor,
    required this.onColorChanged,
    required this.uiOpacity,
    required this.onOpacityChanged,
    required this.onBackgroundImageChanged,
    required this.backgroundImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('الوضع الليلي'),
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (v) => onThemeToggled(),
        ),
        const Divider(),
        const Text('لون التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [const Color(0xFFD4AF37), Colors.blueGrey, Colors.teal, Colors.brown].map((c) => GestureDetector(
            onTap: () => onColorChanged(c),
            child: CircleAvatar(backgroundColor: c, radius: 20, child: primaryColor.toARGB32() == c.toARGB32() ? const Icon(Icons.check, color: Colors.white) : null),
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
