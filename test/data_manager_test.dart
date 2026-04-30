import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:aldhakereen/data/data_manager.dart';

import 'data_manager_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;
  late Directory tempDir;
  late File localFile;

  setUp(() async {
    mockClient = MockClient();

    tempDir = await Directory.systemTemp.createTemp('aldhakereen_test_');
    localFile = File('${tempDir.path}/content.json');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DataManager.syncCloudData', () {
    test('returns false when HTTP request throws an exception', () async {
      when(mockClient.get(any)).thenThrow(Exception('Network Error'));

      final result = await DataManager.syncCloudData(client: mockClient);

      expect(result, isFalse);
    });

    test('returns false when HTTP response status is not 200', () async {
      when(mockClient.get(any)).thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await DataManager.syncCloudData(client: mockClient);

      expect(result, isFalse);
    });

    test('returns false when JSON response is invalid', () async {
      when(mockClient.get(any)).thenAnswer((_) async => http.Response('Invalid JSON', 200));

      final result = await DataManager.syncCloudData(client: mockClient);

      expect(result, isFalse);
    });

    test('returns false when JSON response is valid but missing "sections"', () async {
      final jsonResponse = jsonEncode({'about': {}, 'settings': {}});
      when(mockClient.get(any)).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await DataManager.syncCloudData(client: mockClient);

      expect(result, isFalse);
    });

    test('returns true and writes file when sync is successful and local file does not exist', () async {
      final jsonResponse = jsonEncode({'sections': {}, 'content': {'duas': []}});
      when(mockClient.get(any)).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await DataManager.syncCloudData(client: mockClient);

      expect(result, isTrue);
      expect(await localFile.exists(), isTrue);
      expect(await localFile.readAsString(), jsonResponse);
    });

    test('returns false when local file exists and content is identical', () async {
      final jsonResponse = jsonEncode({'sections': {}, 'content': {'duas': []}});
      await localFile.writeAsString(jsonResponse);
      when(mockClient.get(any)).thenAnswer((_) async => http.Response(jsonResponse, 200));

      final result = await DataManager.syncCloudData(client: mockClient);

      expect(result, isFalse);
    });

    test('returns true, updates file, and increments notifier when sync is successful and local file exists with different content', () async {
      final oldJsonResponse = jsonEncode({'sections': {}, 'content': {'duas': []}});
      final newJsonResponse = jsonEncode({'sections': {}, 'content': {'duas': [], 'new': 'data'}});
      await localFile.writeAsString(oldJsonResponse);
      when(mockClient.get(any)).thenAnswer((_) async => http.Response(newJsonResponse, 200));

      final initialNotifierValue = DataManager.dbNotifier.value;
      final result = await DataManager.syncCloudData(client: mockClient);

      expect(result, isTrue);
      expect(await localFile.readAsString(), newJsonResponse);
      expect(DataManager.dbNotifier.value, initialNotifierValue + 1);
    });
  });
}
