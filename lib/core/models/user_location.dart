/// Wraps a GPS position with relevant metadata.
class UserLocation {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed; // m/s
  final double heading; // degrees
  final DateTime timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
    this.speed = 0,
    this.heading = 0,
    required this.timestamp,
  });

  /// Default fallback location (0, 0).
  factory UserLocation.empty() => UserLocation(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
      );

  bool get isValid => latitude != 0 || longitude != 0;
}
