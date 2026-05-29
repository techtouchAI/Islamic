import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
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
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
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
  await PrayerAlarmService.init();

  try {
    await Firebase.initializeApp();
    // Call the analytics service in a non-blocking way
    AnalyticsService().checkAndRegisterDevice();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  await Hive.initFlutter();
  await FavoritesService.instance.init();
  runApp(ChangeNotifierProvider(create: (_) => SettingsProvider()..init(), child: const AlDhakereenApp()));
}

class AlDhakereenApp extends StatelessWidget {
  const AlDhakereenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'الذاكرين',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SA')],
      locale: const Locale('ar', 'SA'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        appBarTheme: AppBarTheme(backgroundColor: provider.primaryColor.withValues(alpha: provider.uiOpacity)),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Cairo'),
        colorScheme: ColorScheme.fromSeed(
          seedColor: provider.primaryColor,
          brightness: Brightness.light,
          primary: provider.primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
        cardColor: provider.cardColor,
      ),
      darkTheme: ThemeData(
        appBarTheme: AppBarTheme(backgroundColor: provider.primaryColor.withValues(alpha: provider.uiOpacity)),
        useMaterial3: true,
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Cairo'),
        colorScheme: ColorScheme.fromSeed(
          seedColor: provider.primaryColor,
          brightness: Brightness.dark,
          primary: provider.primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardColor: provider.cardColor,
      ),
      themeMode: provider.themeMode,
      home: const SplashScreen(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

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
                    ?.withValues(alpha: context.watch<SettingsProvider>().uiOpacity),
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
                          builder: (context) => SearchScreen().fontSizeFactor),
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
                    if (context.watch<SettingsProvider>().backgroundImagePath != null)
                      Positioned.fill(
                        child: Image.file(
                          File(context.watch<SettingsProvider>().backgroundImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (context.watch<SettingsProvider>().backgroundImagePath == null)
                      Positioned.fill(
                        child: buildImage(
                          context.watch<SettingsProvider>().selectedBase64Bg ??
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
    final providerWatch = context.watch<SettingsProvider>();
    final providerRead = context.read<SettingsProvider>();
    switch (_currentSection) {
      case 'home':
        return HomeSection(
          key: const ValueKey('home'),
          onPrayerCardTap: () => _navigateTo('prayer_times'),
        );
      case 'settings':
        return SettingsSection(
          key: const ValueKey('settings'),
        );

      case 'favorites':
        return FavoritesSection(
          key: const ValueKey('favorites'),
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

        );
      case 'visits':
        return TabbedSection(
          key: const ValueKey('visits'),
          tabs: const ['زيارات الأيام', 'الزيارات العامة'],
          sectionKeys: const ['visits_days', 'visits_general'],

        );
      case 'adhkar':
        return TabbedSection(
          key: const ValueKey('adhkar'),
          tabs: const ['المناجاة', 'التسبيحات'],
          sectionKeys: const ['adhkar_munajat', 'adhkar_tasbihs'],

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

        );
      case 'prophets_stories':
        return DynamicListSection(
          key: const ValueKey('prophets_stories'),
          title: _getSectionTitle('prophets_stories'),
          sectionKey: 'prophets_stories',

        );
      case 'istikhara':
        return IstikharaScreen(key: const ValueKey('istikhara'));
      default:
        return DynamicListSection(
          key: ValueKey(_currentSection),
          title: _getSectionTitle(_currentSection),
          sectionKey: _currentSection,

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








