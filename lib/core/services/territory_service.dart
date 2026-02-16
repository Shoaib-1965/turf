import 'dart:math';

import 'package:latlong2/latlong.dart';

import '../utils/geo_utils.dart';

/// Handles territory capture polygon buffering and area calculation.
class TerritoryService {
  TerritoryService._();

  /// Buffer a polyline route into a corridor polygon (~8m width each side).
  /// Returns the outline as a closed polygon suitable for map rendering.
  static List<LatLng> bufferRoute(List<LatLng> route,
      {double widthMeters = 8}) {
    if (route.length < 2) return [];

    final left = <LatLng>[];
    final right = <LatLng>[];

    for (int i = 0; i < route.length - 1; i++) {
      final p1 = route[i];
      final p2 = route[i + 1];

      final bearing = GeoUtils.bearingDegrees(
        p1.latitude,
        p1.longitude,
        p2.latitude,
        p2.longitude,
      );

      // Perpendicular offsets
      final leftBearing = (bearing - 90) % 360;
      final rightBearing = (bearing + 90) % 360;

      left.add(_offsetPoint(p1, leftBearing, widthMeters));
      right.add(_offsetPoint(p1, rightBearing, widthMeters));

      // Last segment — also offset the end point
      if (i == route.length - 2) {
        left.add(_offsetPoint(p2, leftBearing, widthMeters));
        right.add(_offsetPoint(p2, rightBearing, widthMeters));
      }
    }

    // Build closed polygon: left side forward + right side reversed
    return [...left, ...right.reversed];
  }

  /// Calculate approximate area of a polygon in km² using Shoelace formula
  /// on a projected plane (good enough for small areas < 10 km²).
  static double calculateAreaKm2(List<LatLng> polygon) {
    if (polygon.length < 3) return 0;

    // Use Spherical excess formula for better accuracy
    double areaM2 = 0;
    final n = polygon.length;

    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final lat1 = polygon[i].latitude * pi / 180;
      final lng1 = polygon[i].longitude * pi / 180;
      final lat2 = polygon[j].latitude * pi / 180;
      final lng2 = polygon[j].longitude * pi / 180;

      areaM2 += (lng2 - lng1) * (2 + sin(lat1) + sin(lat2));
    }

    areaM2 =
        (areaM2.abs() * GeoUtils.earthRadiusKm * GeoUtils.earthRadiusKm * 1e6) /
            2;
    return areaM2 / 1e6; // Convert m² to km²
  }

  /// Offset a point by [distanceMeters] at a given [bearingDegrees].
  static LatLng _offsetPoint(
    LatLng origin,
    double bearingDeg,
    double distanceMeters,
  ) {
    const r = GeoUtils.earthRadiusKm * 1000; // meters
    final d = distanceMeters / r;
    final brng = bearingDeg * pi / 180;
    final lat1 = origin.latitude * pi / 180;
    final lng1 = origin.longitude * pi / 180;

    final lat2 = asin(sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(brng));
    final lng2 = lng1 +
        atan2(sin(brng) * sin(d) * cos(lat1), cos(d) - sin(lat1) * sin(lat2));

    return LatLng(lat2 * 180 / pi, lng2 * 180 / pi);
  }
}
