import 'package:aldhakereen/services/release_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReleaseManifest', () {
    Map<String, dynamic> validValues() => <String, dynamic>{
          'version': '1.0.56',
          'build_number': 806,
          'min_supported_build': 805,
          'apk_url': 'https://aldhakereen.com/api/update/aldhakereen.apk',
          'sha256': List.filled(64, 'a').join(),
        };

    test('parses a valid manifest', () {
      final manifest = ReleaseManifest.parse(validValues());
      expect(manifest.version, '1.0.56');
      expect(manifest.buildNumber, 806);
      expect(manifest.minSupportedBuild, 805);
      expect(
        manifest.apkUrl.toString(),
        'https://aldhakereen.com/api/update/aldhakereen.apk',
      );
      expect(manifest.sha256Hex, List.filled(64, 'a').join());
    });

    test('detects an update when the server build is newer', () {
      final manifest = ReleaseManifest.parse(validValues());
      expect(
        manifest.compareWithInstalledApp(
          installedVersion: '1.0.55',
          installedBuildNumber: 805,
        ),
        UpdateCheckStatus.updateAvailable,
      );
    });

    test('reports the app as current when version and build match', () {
      final manifest = ReleaseManifest.parse(validValues());
      expect(
        manifest.compareWithInstalledApp(
          installedVersion: '1.0.56',
          installedBuildNumber: 806,
        ),
        UpdateCheckStatus.upToDate,
      );
    });

    test('reports a stale server instead of offering a downgrade', () {
      final manifest = ReleaseManifest.parse(validValues());
      expect(
        manifest.compareWithInstalledApp(
          installedVersion: '1.0.56',
          installedBuildNumber: 807,
        ),
        UpdateCheckStatus.serverBehind,
      );
    });

    test('reports conflicting version names for the same build', () {
      final manifest = ReleaseManifest.parse(validValues());
      expect(
        manifest.compareWithInstalledApp(
          installedVersion: '1.0.55',
          installedBuildNumber: 806,
        ),
        UpdateCheckStatus.inconsistentVersion,
      );
    });

    test('rejects missing version', () {
      final values = validValues()..remove('version');
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects empty version', () {
      final values = validValues()..['version'] = '';
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects invalid build_number', () {
      final values = validValues()..['build_number'] = -1;
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects min_supported_build greater than build_number', () {
      final values = validValues()..['min_supported_build'] = 900;
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects non-HTTPS apk_url', () {
      final values = validValues()..['apk_url'] = 'http://example.com/app.apk';
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects apk_url that does not end with .apk', () {
      final values = validValues()..['apk_url'] = 'https://example.com/app.zip';
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects invalid sha256 checksum', () {
      final values = validValues()..['sha256'] = 'not-a-valid-hash';
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });
  });

  group('ReleaseManifest.fromGitHubRelease', () {
    final hash = List.filled(64, 'b').join();
    Map<String, dynamic> release() => <String, dynamic>{
          'tag_name': 'v1.0.56-806',
          'assets': [
            {
              'name': 'app-release.apk',
              'digest': 'sha256:$hash',
              'browser_download_url':
                  'https://github.com/techtouchAI/Islamic/releases/download/v1.0.56-806/app-release.apk',
            },
          ],
        };

    test('reads version, build, url and digest from the latest release', () {
      final m = ReleaseManifest.fromGitHubRelease(release());
      expect(m.version, '1.0.56');
      expect(m.buildNumber, 806);
      expect(m.minSupportedBuild, 0);
      expect(m.sha256Hex, hash);
      expect(m.apkUrl.host, 'github.com');
    });

    test('rejects a tag that is not vX.Y.Z-N', () {
      final r = release()..['tag_name'] = 'nightly';
      expect(() => ReleaseManifest.fromGitHubRelease(r), throwsFormatException);
    });

    test('rejects a release without the APK asset', () {
      final r = release()..['assets'] = <dynamic>[];
      expect(() => ReleaseManifest.fromGitHubRelease(r), throwsFormatException);
    });

    test('rejects an APK asset without a sha256 digest', () {
      final r = release();
      (r['assets'] as List).first['digest'] = null;
      expect(() => ReleaseManifest.fromGitHubRelease(r), throwsFormatException);
    });
  });
}
