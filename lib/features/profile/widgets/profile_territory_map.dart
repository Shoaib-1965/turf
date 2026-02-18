import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';

/// Non-interactive territory map thumbnail.
class ProfileTerritoryMap extends StatelessWidget {
  final double territoryKm2;

  const ProfileTerritoryMap({super.key, required this.territoryKm2});

  // Mock territory polygons near Islamabad
  static const _baseLat = 33.6844;
  static const _baseLng = 73.0479;
  static const _d = 0.002;

  static final _polygons = [
    [
      LatLng(_baseLat, _baseLng),
      LatLng(_baseLat + _d, _baseLng),
      LatLng(_baseLat + _d, _baseLng + _d),
      LatLng(_baseLat, _baseLng + _d),
    ],
    [
      LatLng(_baseLat + _d, _baseLng),
      LatLng(_baseLat + 2 * _d, _baseLng),
      LatLng(_baseLat + 2 * _d, _baseLng + _d),
      LatLng(_baseLat + _d, _baseLng + _d),
    ],
    [
      LatLng(_baseLat, _baseLng + _d),
      LatLng(_baseLat + _d, _baseLng + _d),
      LatLng(_baseLat + _d, _baseLng + 2 * _d),
      LatLng(_baseLat, _baseLng + 2 * _d),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MY TERRITORY',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(_baseLat + _d, _baseLng + _d * 0.5),
                    initialZoom: 15.5,
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
                    PolygonLayer(
                      polygons: _polygons
                          .map(
                            (pts) => Polygon(
                              points: pts,
                              color:
                                  AppColors.primaryTeal.withValues(alpha: 0.30),
                              borderColor:
                                  AppColors.primaryTeal.withValues(alpha: 0.60),
                              borderStrokeWidth: 1.5,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$territoryKm2 km² owned',
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
