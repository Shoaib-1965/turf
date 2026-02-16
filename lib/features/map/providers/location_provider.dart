import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/user_location.dart';
import '../../../core/services/location_service.dart';

/// Singleton location service.
final locationServiceProvider = Provider<LocationService>((ref) {
  final svc = LocationService();
  ref.onDispose(() => svc.dispose());
  return svc;
});

/// Checks / requests location permission.
final locationPermissionProvider = FutureProvider<bool>((ref) async {
  final svc = ref.read(locationServiceProvider);
  return svc.requestPermission();
});

/// Current permission status.
final permissionStatusProvider = FutureProvider<LocationPermission>((ref) {
  final svc = ref.read(locationServiceProvider);
  return svc.checkPermission();
});

/// Continuous stream of user positions.
final userLocationProvider = StreamProvider<UserLocation>((ref) {
  final svc = ref.read(locationServiceProvider);
  svc.startListening();
  ref.onDispose(() => svc.stopListening());
  return svc.positionStream;
});

/// One-shot current position.
final currentPositionProvider = FutureProvider<UserLocation>((ref) {
  final svc = ref.read(locationServiceProvider);
  return svc.getCurrentPosition();
});
