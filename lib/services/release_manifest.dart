import 'package:dio/dio.dart';

/// Result of comparing the server's Android build with the installed build.
///
/// Android's build number is authoritative for installability; a higher
/// version name alone cannot be installed when the build number is unchanged.
enum UpdateCheckStatus {
  updateAvailable,
  upToDate,
  serverBehind,
  inconsistentVersion,
}

/// Release manifest for in-app OTA updates.
///
/// The manifest is a simple JSON file hosted on the app's own server,
/// containing the latest version info and a direct APK download link.
/// No GitHub references are used anywhere in the update flow.
///
/// Expected JSON shape:
/// ```json
/// {
///   "version": "1.0.56",
///   "build_number": 806,
///   "min_supported_build": 800,
///   "apk_url": "https://aldhakereen.com/api/update/aldhakereen.apk",
///   "sha256": "abcdef0123456789..."
/// }
/// ```
class ReleaseManifest {
  final String version;
  final int buildNumber;
  final int minSupportedBuild;
  final Uri apkUrl;
  final String sha256Hex;

  const ReleaseManifest({
    required this.version,
    required this.buildNumber,
    required this.minSupportedBuild,
    required this.apkUrl,
    required this.sha256Hex,
  });

  /// Base URL where the release manifest and APK are hosted.
  /// Change this to your own server when deploying.
  static const String _baseUrl = 'https://aldhakereen.com/api/update';
  static const String _manifestUrl = '$_baseUrl/release_manifest.json';

  static ReleaseManifest parse(Map<String, dynamic> json) {
    final version = json['version'];
    final buildNumber = json['build_number'];
    final minimum = json['min_supported_build'];
    final url = Uri.tryParse(json['apk_url']?.toString() ?? '');
    final checksum = json['sha256'];

    if (version is! String || version.isEmpty) {
      throw const FormatException('Invalid manifest: missing version');
    }
    if (buildNumber is! int || buildNumber <= 0) {
      throw const FormatException('Invalid manifest: invalid build_number');
    }
    if (minimum is! int || minimum < 0 || minimum > buildNumber) {
      throw const FormatException(
          'Invalid manifest: invalid min_supported_build');
    }
    if (url == null || url.scheme != 'https' || !url.path.endsWith('.apk')) {
      throw const FormatException('Invalid manifest: invalid apk_url');
    }
    if (checksum is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
      throw const FormatException('Invalid manifest: invalid sha256');
    }

    return ReleaseManifest(
      version: version,
      buildNumber: buildNumber,
      minSupportedBuild: minimum,
      apkUrl: url,
      sha256Hex: checksum,
    );
  }

  /// Compares this manifest with the installed Android app.
  UpdateCheckStatus compareWithInstalledApp({
    required String installedVersion,
    required int installedBuildNumber,
  }) {
    if (buildNumber > installedBuildNumber) {
      return UpdateCheckStatus.updateAvailable;
    }
    if (buildNumber < installedBuildNumber) {
      return UpdateCheckStatus.serverBehind;
    }
    if (version != installedVersion) {
      return UpdateCheckStatus.inconsistentVersion;
    }
    return UpdateCheckStatus.upToDate;
  }

  /// Fetches the release manifest from the app's own update server.
  static Future<ReleaseManifest> fetch({Dio? dio}) async {
    final client = dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
    final response = await client.get<dynamic>(
      _manifestUrl,
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid release manifest response');
    }
    return parse(data);
  }
}
