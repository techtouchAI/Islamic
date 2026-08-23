import 'dart:math' as math;

/// Returns the initial great-circle bearing from a location toward the Kaaba.
double calculateQiblaDirection({
  required double latitude,
  required double longitude,
}) {
  const kaabaLatitude = 21.422487;
  const kaabaLongitude = 39.826206;

  final latitudeRadians = latitude * (math.pi / 180.0);
  const kaabaLatitudeRadians = kaabaLatitude * (math.pi / 180.0);
  final longitudeDifferenceRadians =
      (kaabaLongitude - longitude) * (math.pi / 180.0);
  final y = math.sin(longitudeDifferenceRadians);
  final x = math.cos(latitudeRadians) * math.tan(kaabaLatitudeRadians) -
      math.sin(latitudeRadians) * math.cos(longitudeDifferenceRadians);
  final direction = math.atan2(y, x) * (180.0 / math.pi);
  return (direction + 360.0) % 360.0;
}
