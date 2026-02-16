import 'dart:math';

/// Utility helpers for geographic calculations.
class GeoUtils {
  GeoUtils._();

  static const double earthRadiusKm = 6371.0;
  static const double metersPerDegreeLatitude = 111320.0;

  /// Haversine distance between two lat/lng points, in meters.
  static double distanceInMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c * 1000;
  }

  /// Bearing in degrees from point 1 to point 2.
  static double bearingDegrees(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLng = _toRadians(lng2 - lng1);
    final y = sin(dLng) * cos(_toRadians(lat2));
    final x =
        cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLng);
    return (_toDegrees(atan2(y, x)) + 360) % 360;
  }

  /// Generate a deterministic grid-cell identifier from coordinates.
  static String gridCellId(
    double lat,
    double lng, {
    double cellSizeMeters = 50.0,
  }) {
    final latCell = (lat * metersPerDegreeLatitude / cellSizeMeters).floor();
    final lngCell =
        (lng * metersPerDegreeLatitude * cos(_toRadians(lat)) / cellSizeMeters)
            .floor();
    return '${latCell}_$lngCell';
  }

  /// Speed in km/h between two timed location samples.
  static double speedKmh(
    double lat1,
    double lng1,
    int timestampMs1,
    double lat2,
    double lng2,
    int timestampMs2,
  ) {
    final distM = distanceInMeters(lat1, lng1, lat2, lng2);
    final dtSeconds = (timestampMs2 - timestampMs1) / 1000;
    if (dtSeconds <= 0) return 0;
    return (distM / dtSeconds) * 3.6;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
  static double _toDegrees(double radians) => radians * 180 / pi;
}
