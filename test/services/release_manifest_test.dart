import 'dart:convert';

import 'package:aldhakereen/services/release_manifest.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signed release verifies, tampering with APK URL fails', () async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final values = <String, dynamic>{
      'version': '1.0.56',
      'build_number': 806,
      'min_supported_build': 805,
      'apk_url':
          'https://github.com/techtouchAI/Islamic/releases/download/v1.0.56-806/app-release.apk',
      'sha256': List.filled(64, 'a').join(),
      'signature': '',
    };
    final manifest = ReleaseManifest.parse(values);
    final signature = await algorithm.sign(
      utf8.encode(manifest.signedPayload),
      keyPair: keyPair,
    );
    values['signature'] = base64Encode(signature.bytes);
    expect(await ReleaseManifest.parse(values).verify(publicKey.bytes), isTrue);
    values['apk_url'] =
        'https://github.com/techtouchAI/Islamic/releases/download/other/app-release.apk';
    expect(
        await ReleaseManifest.parse(values).verify(publicKey.bytes), isFalse);
  });
}
