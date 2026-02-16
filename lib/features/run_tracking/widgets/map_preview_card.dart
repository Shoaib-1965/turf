import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/territory_service.dart';

/// Non-interactive map preview showing the run route + captured territory.
class MapPreviewCard extends StatelessWidget {
  final List<LatLng> routePoints;

  const MapPreviewCard({super.key, required this.routePoints});

  @override
  Widget build(BuildContext context) {
    // Calculate bounds for the route
    final bounds = _computeBounds(routePoints);

    // Build territory polygon from route
    final capturePolygon = routePoints.length >= 2
        ? TerritoryService.bufferRoute(routePoints)
        : <LatLng>[];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.80),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: bounds.center,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'com.turf.app',
                  retinaMode: true,
                ),

                // Territory polygon
                if (capturePolygon.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: capturePolygon,
                        color: AppColors.primaryTeal.withValues(alpha: 0.30),
                        borderColor:
                            AppColors.primaryTeal.withValues(alpha: 0.50),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Route polyline
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: AppColors.primaryTeal,
                        strokeWidth: 3.5,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LatLngBounds _computeBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        const LatLng(33.68, 73.04),
        const LatLng(33.69, 73.05),
      );
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      LatLng(minLat - 0.002, minLng - 0.002),
      LatLng(maxLat + 0.002, maxLng + 0.002),
    );
  }
}
