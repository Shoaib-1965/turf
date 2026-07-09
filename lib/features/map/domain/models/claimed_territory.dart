import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Represents an organic territory claimed by a user by running a closed loop.
/// Maps to the `claimed_territories` Supabase table.
class ClaimedTerritory {
  final String id;
  final String ownerId;
  final String? sessionId;
  final List<Position> polygon; // The loop vertices (lng, lat)
  final double areaSqm;
  final double perimeterM;
  final String colorHex;
  final DateTime claimedAt;
  final bool isActive;

  // Joined from profiles (for map rendering)
  final String? ownerName;
  final String? ownerAvatarUrl;
  final int ownerLevel;
  final int ownerXp;
  final String ownerTerraColor;

  ClaimedTerritory({
    required this.id,
    required this.ownerId,
    this.sessionId,
    required this.polygon,
    required this.areaSqm,
    required this.perimeterM,
    this.colorHex = '#00E676',
    required this.claimedAt,
    this.isActive = true,
    this.ownerName,
    this.ownerAvatarUrl,
    this.ownerLevel = 1,
    this.ownerXp = 0,
    this.ownerTerraColor = '#00E676',
  });

  factory ClaimedTerritory.fromJson(Map<String, dynamic> json) {
    // Parse the GeoJSON polygon stored in `geom`
    List<Position> polygon = [];
    try {
      final geom = json['geom'];
      if (geom is Map<String, dynamic>) {
        // GeoJSON format: { "type": "Polygon", "coordinates": [[[lng, lat], ...]] }
        final coords = geom['coordinates'];
        if (coords is List && coords.isNotEmpty) {
          final ring = coords[0] as List;
          for (var point in ring) {
            final p = point as List;
            polygon.add(Position(
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ));
          }
        }
      } else if (geom is String) {
        // Sometimes PostGIS returns WKT or a stringified JSON — handle gracefully
        // For now, leave polygon empty and log
      }
    } catch (_) {
      // Graceful fallback: empty polygon
    }

    // Profile join fields
    final profile = json['profiles'];

    return ClaimedTerritory(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      sessionId: json['session_id'] as String?,
      polygon: polygon,
      areaSqm: (json['area_sqm'] as num?)?.toDouble() ?? 0,
      perimeterM: (json['perimeter_m'] as num?)?.toDouble() ?? 0,
      colorHex: json['color_hex'] as String? ?? '#00E676',
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      ownerName: profile != null ? profile['full_name'] as String? : null,
      ownerAvatarUrl: profile != null ? profile['avatar_url'] as String? : null,
      ownerLevel: profile != null ? (profile['level'] as num?)?.toInt() ?? 1 : 1,
      ownerXp: profile != null ? (profile['total_xp'] as num?)?.toInt() ?? 0 : 0,
      ownerTerraColor: profile != null ? (profile['terra_color'] as String?) ?? '#00E676' : '#00E676',
    );
  }

  /// Convert the polygon to GeoJSON for Supabase insert.
  /// PostGIS geography(Polygon, 4326) accepts GeoJSON.
  Map<String, dynamic> toGeoJsonGeom() {
    final ring = polygon.map((p) => [p.lng.toDouble(), p.lat.toDouble()]).toList();
    // GeoJSON Polygon must be closed (first == last)
    if (ring.isNotEmpty && (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add(List.from(ring.first));
    }
    return {
      'type': 'Polygon',
      'coordinates': [ring],
    };
  }

  /// Nicely formatted area string.
  String get formattedArea {
    if (areaSqm < 10000) {
      return '${_formatNumber(areaSqm.round())} m²';
    } else if (areaSqm < 1000000) {
      return '${(areaSqm / 10000).toStringAsFixed(1)} hectares';
    } else {
      return '${(areaSqm / 1000000).toStringAsFixed(2)} km²';
    }
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
