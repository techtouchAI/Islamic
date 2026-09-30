import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import 'release_manifest.dart';

/// In-app OTA updater — downloads APK directly from the app's own server
/// and triggers the system installer without any browser or GitHub redirect.
///
/// Flow:
///   1. Fetch `release_manifest.json` from the update server
///   2. Download the APK with visible progress
///   3. Verify SHA-256 checksum
///   4. Open the APK through the system installer via `open_filex`
class OTAService {
  static final OTAService _instance = OTAService._internal();
  static OTAService get instance => _instance;

  OTAService._internal();

  /// Download progress in `0.0..1.0` while downloading/installing,
  /// `-1.0` when idle or after a failure.
  final ValueNotifier<double> downloadProgress = ValueNotifier(-1.0);
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;

  /// Fetches the release manifest from the app's own update server.
  Future<ReleaseManifest> fetchManifest() => ReleaseManifest.fetch();

  Future<void> downloadAndInstallApk(
    String url,
    String? expectedChecksum, {
    required Function(String) onError,
    void Function()? onSuccess,
  }) async {
    if (_isDownloading) return;
    if (kIsWeb || !Platform.isAndroid) {
      onError('التحديث الداخلي مدعوم على أندرويد فقط.');
      return;
    }
    final uri = Uri.tryParse(url);
    final checksum = expectedChecksum?.toLowerCase();
    if (uri == null ||
        uri.scheme != 'https' ||
        checksum == null ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
      onError('لا يمكن تثبيت تحديث دون رابط آمن وبصمة تحقق موثوقة.');
      return;
    }

    // Ensure the user has granted install permission.
    var installStatus = await Permission.requestInstallPackages.status;
    if (!installStatus.isGranted) {
      installStatus = await Permission.requestInstallPackages.request();
      if (!installStatus.isGranted) {
        onError('يجب منح صلاحية تثبيت التطبيقات لتتمكن من تحديث التطبيق');
        return;
      }
    }

    _isDownloading = true;
    downloadProgress.value = 0.0;
    var installTriggered = false;

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/aldhakereen-update.apk';

      final Dio dio = Dio();

      // Download the APK directly — progress is observed via [downloadProgress].
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = received / total;
          }
        },
      );

      final File file = File(savePath);

      // SHA-256 validation — must succeed before anything is installed.
      final fileChecksum =
          (await sha256.bind(file.openRead()).first).toString();
      if (fileChecksum != checksum) {
        await file.delete();
        onError('تعذر التحديث: الملف لا يطابق بصمة التحقق.');
        return;
      }

      downloadProgress.value = 1.0;
      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        onError('تعذر فتح مُثبّت التحديث: ${result.message}');
        return;
      }
      installTriggered = true;
      onSuccess?.call();
    } catch (e) {
      debugPrint("Download/Install error: $e");
      onError('فشل تحميل التحديث');
    } finally {
      if (!installTriggered) {
        downloadProgress.value = -1.0;
      }
      _isDownloading = false;
    }
  }
}
