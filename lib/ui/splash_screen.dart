import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../data/data_manager.dart';
import '../services/search_engine.dart';
import '../services/quran_service.dart';
import '../main.dart'; // To access MainScaffold or replace later

class SplashScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final double fontSizeFactor;
  final Function(double) onFontSizeChanged;
  final VoidCallback onThemeToggled;
  final Color primaryColor;
  final Function(Color) onColorChanged;
  final double uiOpacity;
  final Function(double) onOpacityChanged;
  final String? backgroundImagePath;
  final String? selectedBase64Bg;
  final Function(String?) onBackgroundImageChanged;
  final Function(String?) onBase64BgChanged;
  final Color cardColor;
  final Function(Color) onCardColorChanged;
  final Map<String, bool> homeVisibility;
  final Function(String, bool) onVisibilityChanged;
  final int hijriAdjustment;
  final Function(int) onHijriAdjustmentChanged;

  const SplashScreen({
    Key? key,
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
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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
      await SearchEngine.instance.init();
      await QuranService.initDB();

      // Wait for content to be fully synced
      await DataManager.syncCloudData();

      if (!mounted) return;
      await _checkForUpdates();
    } catch (e) {
      debugPrint("Initialization Error in Splash: $e");
      if (mounted) _navigateToHome();
    }
  }

  Future<void> _checkForUpdates() async {
    final settings = DataManager.getSettings();
    final latestVersionCode = settings['latest_version_code'] as int? ?? 1;
    final forceUpdate = settings['force_update'] as bool? ?? false;
    final updateUrl = settings['update_url'] as String? ?? "";

    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(info.buildNumber) ?? 1;

      if (currentVersionCode < latestVersionCode && updateUrl.isNotEmpty) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: !forceUpdate,
          builder: (context) {
            return PopScope(
              canPop: !forceUpdate,
              child: AlertDialog(
                title: const Text('تحديث متوفر', textAlign: TextAlign.right),
                content: const Text(
                  'نسخة جديدة من التطبيق متوفرة. يرجى التحديث للحصول على أفضل تجربة.',
                  textAlign: TextAlign.right,
                ),
                actions: [
                  if (!forceUpdate)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToHome();
                      },
                      child: const Text('تخطي'),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse(updateUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('تحديث الآن'),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint("Update Check Error: $e");
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScaffold(
          themeMode: widget.themeMode,
          fontSizeFactor: widget.fontSizeFactor,
          onFontSizeChanged: widget.onFontSizeChanged,
          onThemeToggled: widget.onThemeToggled,
          primaryColor: widget.primaryColor,
          onColorChanged: widget.onColorChanged,
          uiOpacity: widget.uiOpacity,
          onOpacityChanged: widget.onOpacityChanged,
          backgroundImagePath: widget.backgroundImagePath,
          selectedBase64Bg: widget.selectedBase64Bg,
          onBackgroundImageChanged: widget.onBackgroundImageChanged,
          onBase64BgChanged: widget.onBase64BgChanged,
          cardColor: widget.cardColor,
          onCardColorChanged: widget.onCardColorChanged,
          homeVisibility: widget.homeVisibility,
          onVisibilityChanged: widget.onVisibilityChanged,
          hijriAdjustment: widget.hijriAdjustment,
          onHijriAdjustmentChanged: widget.onHijriAdjustmentChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 100),
            const SizedBox(height: 20),
            Text(
              DataManager.getMainScreenDua(),
              style: const TextStyle(
                fontFamily: 'me_quran',
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
