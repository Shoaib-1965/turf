import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/user_location.dart';

/// Wraps [Geolocator] for permission management and continuous GPS streaming.
class LocationService {
  StreamSubscription<Position>? _positionSub;
  final _controller = StreamController<UserLocation>.broadcast();

  /// Stream of filtered user positions (accuracy < 20 m).
  Stream<UserLocation> get positionStream => _controller.stream;

  // ── Permissions ──────────────────────────────────────────

  /// Returns `true` when the app has at-least "while in use" permission.
  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  /// Current permission status.
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  // ── Single read ──────────────────────────────────────────

  Future<UserLocation> getCurrentPosition() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return _mapPosition(pos);
  }

  // ── Continuous stream ────────────────────────────────────

  void startListening() {
    _positionSub?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .where((p) => p.accuracy <= 20) // drop inaccurate fixes
        .listen(
          (pos) => _controller.add(_mapPosition(pos)),
          onError: (e) => _controller.addError(e),
        );
  }

  void stopListening() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void dispose() {
    stopListening();
    _controller.close();
  }

  // ── Helpers ──────────────────────────────────────────────

  UserLocation _mapPosition(Position pos) => UserLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: pos.timestamp,
      );
}
