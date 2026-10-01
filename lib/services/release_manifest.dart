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
/// The source of truth is the latest GitHub Release of this repository
/// (the same approach used by the SUN app). The release tag has the form
/// `v<version>-<build>` (e.g. `v1.0.56-806`, created by the release workflow)
/// and carries the APK as an asset whose SHA-256 `digest` is published by
/// GitHub itself. No private server is needed, so the check cannot fail
/// because of a missing domain.
///
/// [parse] still accepts the flat JSON shape below, used by tests and by the
/// optional signed `release_manifest.json` asset:
/// ```json
/// {
///   "version": "1.0.56",
///   "build_number": 806,
///   "min_supported_build": 800,
///   "apk_url": "https://github.com/.../app-release.apk",
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

  static const String repoOwner = 'techtouchAI';
  static const String repoName = 'Islamic';
  static const String apkAssetName = 'app-release.apk';
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  /// Builds a manifest from the GitHub "latest release" API payload.
  ///
  /// Throws [FormatException] with an Arabic-friendly diagnostic when the
  /// release has no usable APK asset, digest, or version tag.
  static ReleaseManifest fromGitHubRelease(
    Map<String, dynamic> release, {
    int minSupportedBuild = 0,
  }) {
    final tag = release['tag_name'];
    if (tag is! String) {
      throw const FormatException('Invalid release: missing tag_name');
    }
    final match =
        RegExp(r'^v?(\d+(?:\.\d+)*)[-+](\d+)$').firstMatch(tag.trim());
    if (match == null) {
      throw FormatException('Invalid release tag (expected vX.Y.Z-N): $tag');
    }

    final assets = release['assets'];
    if (assets is! List) {
      throw const FormatException('Invalid release: missing assets');
    }
    Map<String, dynamic>? apk;
    for (final item in assets) {
      if (item is Map && item['name'] == apkAssetName) {
        apk = Map<String, dynamic>.from(item);
        break;
      }
    }
    if (apk == null) {
      throw const FormatException('Release has no app-release.apk asset');
    }
    final digest = apk['digest']?.toString().toLowerCase() ?? '';
    final hash =
        digest.startsWith('sha256:') ? digest.substring('sha256:'.length) : '';
    final build = int.parse(match.group(2)!);

    return parse(<String, dynamic>{
      'version': match.group(1),
      'build_number': build,
      'min_supported_build':
          minSupportedBuild > build ? build : minSupportedBuild,
      'apk_url': apk['browser_download_url'],
      'sha256': hash,
    });
  }

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

  /// Fetches the latest release from GitHub Releases.
  static Future<ReleaseManifest> fetch({Dio? dio}) async {
    final client = dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        );
    final response = await client.get<dynamic>(
      latestReleaseUrl,
      options: Options(
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'aldhakereen-OTA',
          'Cache-Control': 'no-cache',
        },
      ),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid release response');
    }
    return fromGitHubRelease(data);
  }
}
