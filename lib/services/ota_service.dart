import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

class OTAService {
  static final OTAService _instance = OTAService._internal();
  static OTAService get instance => _instance;

  OTAService._internal();

  final ValueNotifier<double> downloadProgress = ValueNotifier(-1.0);
  bool _isDownloading = false;

  Future<void> downloadAndInstallApk(
    String url,
    String? expectedChecksum, {
    required Function(String) onError,
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

    if (Platform.isAndroid) {
      var installStatus = await Permission.requestInstallPackages.status;
      if (!installStatus.isGranted) {
        installStatus = await Permission.requestInstallPackages.request();
        if (!installStatus.isGranted) {
          onError('يجب منح صلاحية تثبيت التطبيقات لتتمكن من تحديث التطبيق');
          return;
        }
      }
    }

    _isDownloading = true;
    downloadProgress.value = 0.0;

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/app-update.apk';

      final Dio dio = Dio();

      // الفصل عن الواجهة: التنزيل يعمل بشكل مستقل هنا
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
          }
        },
      );

      final File file = File(savePath);

      final fileChecksum =
          (await sha256.bind(file.openRead()).first).toString();
      if (fileChecksum != checksum) {
        await file.delete();
        onError('تعذر التحديث: الملف لا يطابق بصمة التحقق.');
        return;
      }

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        onError('تعذر فتح مُثبّت التحديث: ${result.message}');
      }
    } catch (e) {
      debugPrint("Download/Install error: $e");
      downloadProgress.value = -1.0;
      onError('فشل تحميل التحديث');
    } finally {
      downloadProgress.value = -1.0;
      _isDownloading = false;
    }
  }
}
