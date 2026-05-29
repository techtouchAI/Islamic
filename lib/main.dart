import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'services/analytics_service.dart';

import 'sections/tasbih_section.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/data_manager.dart';
import 'services/prayer_alarm_service.dart';
import 'sections/favorites_section.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'search/screens/search_screen.dart';
import 'ui/calendar/hijri_calendar_screen.dart';
import 'ui/qibla/qibla_screen.dart';

import 'ui/widgets/app_drawer.dart';
import 'ui/splash_screen.dart';
import 'ui/home/home_section.dart';
import 'ui/about/about_section.dart';
import 'ui/tabs/tabbed_section.dart';
import 'ui/dynamic_list/dynamic_list_section.dart';
import 'ui/settings/settings_section.dart';
import 'ui/prayer_times/prayer_times_section.dart';

import 'dart:math';
import 'dart:io';
import 'presentation/screens/istikhara_screen.dart';

class IslamicPatternPainter extends CustomPainter {
  final Color color;
  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.8;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      path.moveTo(center.dx, center.dy);
      path.lineTo(x, y);

      final nextAngle = (i + 1) * pi / 4;
      final nextX = center.dx + radius * cos(nextAngle);
      final nextY = center.dy + radius * sin(nextAngle);
      path.quadraticBezierTo(
        center.dx + radius * 1.5 * cos((angle + nextAngle) / 2),
        center.dy + radius * 1.5 * sin((angle + nextAngle) / 2),
        nextX,
        nextY,
      );
    }

    canvas.drawPath(path, paint);

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        center,
        radius * (0.2 + i * 0.2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

Widget buildImage(String? base64String,
    {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (base64String == null || base64String.isEmpty) {
    return Image.asset(
      'assets/images/Mscreen/2.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
  return Image.asset(
    base64String,
    width: width,
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
    AnalyticsService().checkAndRegisterDevice();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
  await Hive.initFlutter();
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
    final provider = context.watch<SettingsProvider>();

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
                    ?.withValues(alpha: provider.uiOpacity),
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
                          builder: (context) => const SearchScreen(),
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
                    if (provider.backgroundImagePath != null)
                      Positioned.fill(
                        child: Image.file(
                          File(provider.backgroundImagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (provider.backgroundImagePath == null)
                      Positioned.fill(
                        child: buildImage(
                          provider.selectedBase64Bg ??
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
          onPrayerCardTap: () => _navigateTo('prayer_times'),
        );
      case 'settings':
        return const SettingsSection(
          key: ValueKey('settings'),
        );

      case 'favorites':
        return const FavoritesSection(
          key: ValueKey('favorites'),
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
        return const TabbedSection(
          key: ValueKey('duas'),
          tabs: [
            'أدعية الأيام',
            'تعقيبات الصلاة',
            'الأدعية العامة',
            'الصلوات',
          ],
          sectionKeys: [
            'duas_days',
            'duas_taqeebat',
            'duas_general',
            'duas_salawat',
          ],
        );
      case 'visits':
        return const TabbedSection(
          key: ValueKey('visits'),
          tabs: ['زيارات الأيام', 'الزيارات العامة'],
          sectionKeys: ['visits_days', 'visits_general'],
        );
      case 'adhkar':
        return const TabbedSection(
          key: ValueKey('adhkar'),
          tabs: ['المناجاة', 'التسبيحات'],
          sectionKeys: ['adhkar_munajat', 'adhkar_tasbihs'],
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
        return const IstikharaScreen(key: ValueKey('istikhara'));
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

IconData getMaterialIcon(String? name) {
  switch (name) {
    case 'book': return Icons.book;
    case 'mosque': return Icons.mosque;
    case 'star': return Icons.star;
    case 'article': return Icons.article;
    case 'menu_book': return Icons.menu_book;
    case 'import_contacts': return Icons.import_contacts;
    case 'wb_sunny': return Icons.wb_sunny;
    case 'nightlight_round': return Icons.nightlight_round;
    case 'favorite': return Icons.favorite;
    case 'search': return Icons.search;
    case 'settings': return Icons.settings;
    case 'info': return Icons.info;
    case 'library_books': return Icons.library_books;
    case 'collections_bookmark': return Icons.collections_bookmark;
    case 'auto_stories': return Icons.auto_stories;
    case 'chrome_reader_mode': return Icons.chrome_reader_mode;
    case 'live_help': return Icons.live_help;
    case 'local_library': return Icons.local_library;
    case 'format_quote': return Icons.format_quote;
    default: return Icons.folder;
  }
}
