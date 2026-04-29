import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:aldhakereen/services/prayer_times_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerTimesService - getCurrentLocation', () {
    const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    int checkPermissionCallCount = 0;
    int requestPermissionsCallCount = 0;

    // 0 = denied, 1 = granted, 2 = restricted, 3 = limited, 4 = permanentlyDenied, 5 = provisional
    int mockStatus = 1; // Default to granted
    Map<int, int> mockRequestResult = {3: 1}; // Default request returns granted for location

    setUp(() {
      checkPermissionCallCount = 0;
      requestPermissionsCallCount = 0;
      mockStatus = 1;
      mockRequestResult = {3: 1};

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          checkPermissionCallCount++;
          return mockStatus;
        }
        if (methodCall.method == 'requestPermissions') {
          requestPermissionsCallCount++;
          return mockRequestResult;
        }
        if (methodCall.method == 'openAppSettings') {
          return true;
        }
        return null;
      });
    });

    test('returns null when permission is denied initially and remains denied after request', () async {
      mockStatus = 0; // denied
      mockRequestResult = {3: 0}; // request returns denied

      final service = PrayerTimesService();
      final result = await service.getCurrentLocation();

      expect(result, isNull);
      expect(checkPermissionCallCount, 1);
      expect(requestPermissionsCallCount, 1);
    });

    test('returns null when permission is permanently denied', () async {
      mockStatus = 4; // permanently denied

      final service = PrayerTimesService();
      final result = await service.getCurrentLocation();

      expect(result, isNull);
      expect(checkPermissionCallCount, 1);
      expect(requestPermissionsCallCount, 0); // Should not request if permanently denied
    });
  });
}
