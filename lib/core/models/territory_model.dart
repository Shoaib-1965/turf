import 'package:latlong2/latlong.dart';

/// Type of territory ownership.
enum TerritoryType { own, friend, enemy, unclaimed }

/// A single territory cell on the map.
class TerritoryModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final List<LatLng> coordinates;
  final double areaKm2;
  final TerritoryType type;
  final DateTime capturedAt;

  const TerritoryModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.coordinates,
    required this.areaKm2,
    required this.type,
    required this.capturedAt,
  });

  /// Convenience: how many days ago this was captured.
  int get daysSinceCaptured => DateTime.now().difference(capturedAt).inDays;
}
