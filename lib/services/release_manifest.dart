import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

/// The public key is injected at build time; an absent key disables OTA.
/// Never trust a URL, checksum or minimum build before signature verification.
class ReleaseManifest {
  final String version;
  final int buildNumber;
  final int minSupportedBuild;
  final Uri apkUrl;
  final String sha256Hex;
  final String signatureBase64;

  const ReleaseManifest({
    required this.version,
    required this.buildNumber,
    required this.minSupportedBuild,
    required this.apkUrl,
    required this.sha256Hex,
    required this.signatureBase64,
  });

  String get signedPayload =>
      '$version\n$buildNumber\n$minSupportedBuild\n$apkUrl\n$sha256Hex';

  static ReleaseManifest parse(Map<String, dynamic> json) {
    final version = json['version'];
    final buildNumber = json['build_number'];
    final minimum = json['min_supported_build'];
    final url = Uri.tryParse(json['apk_url']?.toString() ?? '');
    final checksum = json['sha256'];
    final signature = json['signature'];
    if (version is! String ||
        version.isEmpty ||
        version.contains('\n') ||
        buildNumber is! int ||
        buildNumber <= 0 ||
        minimum is! int ||
        minimum < 0 ||
        minimum > buildNumber ||
        url == null ||
        url.scheme != 'https' ||
        url.host != 'github.com' ||
        !url.path.endsWith('.apk') ||
        checksum is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum) ||
        signature is! String) {
      throw const FormatException('Invalid release manifest');
    }
    return ReleaseManifest(
      version: version,
      buildNumber: buildNumber,
      minSupportedBuild: minimum,
      apkUrl: url,
      sha256Hex: checksum,
      signatureBase64: signature,
    );
  }

  Future<bool> verify(List<int> publicKeyBytes) async {
    if (publicKeyBytes.length != 32) return false;
    try {
      return await Ed25519().verify(
        utf8.encode(signedPayload),
        signature: Signature(
          base64Decode(signatureBase64),
          publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<ReleaseManifest> fetchVerified(
      Dio dio, List<int> publicKey) async {
    if (publicKey.length != 32) {
      throw StateError('OTA signing public key is not configured');
    }
    final response = await dio.get<dynamic>(
      'https://github.com/techtouchAI/Islamic/releases/latest/download/release_manifest.json',
      options: Options(responseType: ResponseType.json),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid release manifest response');
    }
    final manifest = parse(data);
    if (!await manifest.verify(publicKey)) {
      throw const FormatException('Invalid release manifest signature');
    }
    return manifest;
  }
}
