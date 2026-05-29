import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../data/data_manager.dart';
import '../services/search_engine.dart';
import '../services/quran_service.dart';
import '../main.dart';
 // To access MainScaffold or replace later

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _downloadProgress = -1.0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    // إعداد تأثير النبض/التلاشي لعبارة الصلاة على محمد وآل محمد
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
            return StatefulBuilder(builder: (context, setDialogState) {
              return PopScope(
                canPop: !forceUpdate && _downloadProgress < 0,
                child: AlertDialog(
                  title: const Text('تحديث متوفر', textAlign: TextAlign.right),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'نسخة جديدة من التطبيق متوفرة. يرجى التحديث للحصول على أفضل تجربة.',
                        textAlign: TextAlign.right,
                      ),
                      if (_downloadProgress >= 0) ...[
                        const SizedBox(height: 20),
                        LinearProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 10),
                        Text('${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                      ],
                    ],
                  ),
                  actions: [
                    if (!forceUpdate && _downloadProgress < 0)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToHome();
                        },
                        child: const Text('تخطي'),
                      ),
                    if (_downloadProgress < 0)
                      ElevatedButton(
                        onPressed: () async {
                          await _downloadAndInstallApk(updateUrl, setDialogState);
                        },
                        child: const Text('تحديث الآن'),
                      ),
                  ],
                ),
              );
            });
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

  Future<void> _downloadAndInstallApk(String url, StateSetter setDialogState) async {
    // 1. Request permissions
    if (Platform.isAndroid) {
      // Storage permissions
      if (await Permission.storage.request().isDenied) {
        // Handle denied permission (you might want to show a message)
      }
      // Install permissions (Android 8+)
      if (await Permission.requestInstallPackages.request().isDenied) {
        // Handle denied permission
      }
    }

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/app-update.apk';

      final Dio dio = Dio();

      setDialogState(() {
        _downloadProgress = 0.0;
      });

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setDialogState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      // Reset progress indicator after download
      setDialogState(() {
        _downloadProgress = -1.0;
      });

      // 3. Trigger Installation
      final result = await OpenFile.open(savePath);
      debugPrint("OpenFile result: ${result.message}");

    } catch (e) {
      debugPrint("Download/Install error: $e");
      setDialogState(() {
        _downloadProgress = -1.0; // Reset on error
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحميل التحديث')),
        );
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainScaffold(),
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
            const SizedBox(height: 30),
            // النص المتحرك بديلاً عن الدائرة
            FadeTransition(
              opacity: _fadeController,
              child: Text(
                'اللهم صل على محمد وال محمد',
                style: TextStyle(
                  fontFamily: 'me_quran',
                  fontSize: 22,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
