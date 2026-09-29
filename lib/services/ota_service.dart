import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import 'release_manifest.dart';

/// Trusted in-app OTA updater.
///
/// Flow: fetch the signed `release_manifest.json` -> download the APK with a
/// visible progress value -> enforce SHA-256 validation -> install locally
/// with `open_filex`. No browser/url_launcher redirect is ever used.
class OTAService {
  static final OTAService _instance = OTAService._internal();
  static OTAService get instance => _instance;

  OTAService._internal();

  /// Download progress in `0.0..1.0` while downloading/installing,
  /// `-1.0` when idle or after a failure (UI may then be dismissed/retried).
  final ValueNotifier<double> downloadProgress = ValueNotifier(-1.0);
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;

  /// Fetches and Ed25519-verifies `release_manifest.json` from the latest
  /// GitHub release. Throws if the manifest is missing, malformed or the
  /// signature does not verify against [publicKeyBytes].
  Future<ReleaseManifest> fetchManifest(List<int> publicKeyBytes) =>
      ReleaseManifest.fetchVerified(Dio(), publicKeyBytes);

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
      final String savePath = '${tempDir.path}/app-update.apk';

      final Dio dio = Dio();

      // Download runs independently from the UI; progress is observed via
      // [downloadProgress] (unskippable progress bar in the update dialog).
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

      // SHA-256 validation must succeed before anything may be installed.
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
      // Keep the bar at 100% (unskippable) while the installer is on screen;
      // only release it when the attempt failed or was aborted.
      if (!installTriggered) {
        downloadProgress.value = -1.0;
      }
      _isDownloading = false;
    }
  }
}
