import 'package:aldhakereen/services/release_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReleaseManifest.parse', () {
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
      final values = validValues()
        ..['apk_url'] = 'http://example.com/app.apk';
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects apk_url that does not end with .apk', () {
      final values = validValues()
        ..['apk_url'] = 'https://example.com/app.zip';
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });

    test('rejects invalid sha256 checksum', () {
      final values = validValues()..['sha256'] = 'not-a-valid-hash';
      expect(() => ReleaseManifest.parse(values), throwsFormatException);
    });
  });
}
