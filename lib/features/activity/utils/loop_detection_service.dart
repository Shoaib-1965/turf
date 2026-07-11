import 'dart:math';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' if (dart.library.html) 'package:turf_app/core/utils/platform_utils.dart';

/// Result of a successful loop detection.
class DetectedLoop {
  /// The polygon vertices in Position (lng, lat) order.
  final List<Position> polygon;

  /// Area in square meters.
  final double areaSqm;

  /// Perimeter in meters.
  final double perimeterM;

  /// The index range in the original path that was consumed by this loop.
  /// pathPoints[startIndex..endIndex] formed the loop.
  final int startIndex;
  final int endIndex;

  DetectedLoop({
    required this.polygon,
    required this.areaSqm,
    required this.perimeterM,
    required this.startIndex,
    required this.endIndex,
  });
}

/// Core algorithm for detecting closed loops in a GPS path.
///
/// When a user's path crosses back over itself, the enclosed area
/// becomes a "claimed territory." Uses equirectangular projection
/// for local flat-meter coordinate conversion (accurate for small areas).
class LoopDetectionService {
  /// Minimum area in sqm to accept a loop (filters GPS jitter).
  static const double minAreaSqm = 150.0;

  /// Minimum number of GPS points in a valid loop.
  static const int minPoints = 8;

  /// Number of trailing segments to skip (avoids false positives from jitter).
  static const int skipTrailingSegments = 5;

  /// Check if the newest segment of [pathPoints] intersects any prior segment.
  /// Returns a [DetectedLoop] if a valid loop is found, null otherwise.
  static DetectedLoop? checkForLoop(List<Position> pathPoints) {
    if (pathPoints.length < minPoints + skipTrailingSegments) return null;

    final int lastIdx = pathPoints.length - 1;
    final Position p3 = pathPoints[lastIdx - 1]; // start of newest segment
    final Position p4 = pathPoints[lastIdx]; // end of newest segment

    // Reference point for equirectangular projection (center of path)
    final double refLat = p4.lat.toDouble();
    final double refLng = p4.lng.toDouble();

    // Convert newest segment to local meters
    final _Point m3 = _toLocalMeters(p3, refLat, refLng);
    final _Point m4 = _toLocalMeters(p4, refLat, refLng);

    // Check against all prior segments except the last `skipTrailingSegments`
    final int checkUpTo = lastIdx - skipTrailingSegments;

    for (int i = 0; i < checkUpTo; i++) {
      final Position p1 = pathPoints[i];
      final Position p2 = pathPoints[i + 1];

      final _Point m1 = _toLocalMeters(p1, refLat, refLng);
      final _Point m2 = _toLocalMeters(p2, refLat, refLng);

      final _Point? intersection = _segmentIntersection(m1, m2, m3, m4);
      if (intersection != null) {
        // Found an intersection at segment index i.
        // The closed loop = pathPoints[i] through pathPoints[end],
        // plus the intersection point as closing vertex.

        // Convert intersection back to Position
        final Position intersectionPos = _fromLocalMeters(intersection, refLat, refLng);

        // Build the loop polygon
        final List<Position> loopPoints = [intersectionPos];
        for (int j = i + 1; j <= lastIdx; j++) {
          loopPoints.add(pathPoints[j]);
        }
        loopPoints.add(intersectionPos); // close the polygon

        if (loopPoints.length < minPoints) continue;

        // Convert loop to local meters for area/perimeter calculation
        final List<_Point> loopMeters = loopPoints.map((p) => _toLocalMeters(p, refLat, refLng)).toList();

        final double area = _shoelaceArea(loopMeters);
        if (area < minAreaSqm) continue;

        final double perimeter = _calculatePerimeter(loopMeters);

        return DetectedLoop(
          polygon: loopPoints,
          areaSqm: area,
          perimeterM: perimeter,
          startIndex: i,
          endIndex: lastIdx,
        );
      }
    }

    return null;
  }

  // ─── Equirectangular Projection ───────────────────────────────

  static _Point _toLocalMeters(Position pos, double refLat, double refLng) {
    const double earthRadius = 6371000.0; // meters
    final double latRad = refLat * pi / 180.0;

    final double x = (pos.lng.toDouble() - refLng) * pi / 180.0 * earthRadius * cos(latRad);
    final double y = (pos.lat.toDouble() - refLat) * pi / 180.0 * earthRadius;
    return _Point(x, y);
  }

  static Position _fromLocalMeters(_Point m, double refLat, double refLng) {
    const double earthRadius = 6371000.0;
    final double latRad = refLat * pi / 180.0;

    final double lng = refLng + (m.x / (earthRadius * cos(latRad))) * 180.0 / pi;
    final double lat = refLat + (m.y / earthRadius) * 180.0 / pi;
    return Position(lng, lat);
  }

  // ─── Segment Intersection (Orientation / Cross-Product) ──────

  /// Returns the intersection point if segments (p1→p2) and (p3→p4) cross,
  /// or null if they don't.
  static _Point? _segmentIntersection(_Point p1, _Point p2, _Point p3, _Point p4) {
    final double d1x = p2.x - p1.x;
    final double d1y = p2.y - p1.y;
    final double d2x = p4.x - p3.x;
    final double d2y = p4.y - p3.y;

    final double denom = d1x * d2y - d1y * d2x;
    if (denom.abs() < 1e-10) return null; // parallel or collinear

    final double t = ((p3.x - p1.x) * d2y - (p3.y - p1.y) * d2x) / denom;
    final double u = ((p3.x - p1.x) * d1y - (p3.y - p1.y) * d1x) / denom;

    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return _Point(p1.x + t * d1x, p1.y + t * d1y);
    }
    return null;
  }

  // ─── Shoelace Formula (Area of polygon in flat meters) ───────

  static double _shoelaceArea(List<_Point> points) {
    double sum = 0;
    final int n = points.length;
    for (int i = 0; i < n; i++) {
      final _Point current = points[i];
      final _Point next = points[(i + 1) % n];
      sum += current.x * next.y - next.x * current.y;
    }
    return sum.abs() / 2.0;
  }

  // ─── Perimeter ───────────────────────────────────────────────

  static double _calculatePerimeter(List<_Point> points) {
    double perimeter = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final dx = points[i + 1].x - points[i].x;
      final dy = points[i + 1].y - points[i].y;
      perimeter += sqrt(dx * dx + dy * dy);
    }
    return perimeter;
  }
}

/// Simple 2D point for local meter coordinates.
class _Point {
  final double x;
  final double y;
  const _Point(this.x, this.y);
}
