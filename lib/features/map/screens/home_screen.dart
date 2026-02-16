import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/territory_model.dart';
import '../providers/location_provider.dart';
import '../providers/territories_provider.dart';
import '../widgets/map_controls.dart';
import '../widgets/territory_info_sheet.dart';
import '../widgets/territory_overlay.dart';
import '../widgets/user_marker.dart';

// ── Tile URLs ─────────────────────────────────────────────
const _lightTileUrl =
    'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';
const _satelliteTileUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();

  bool _isLightTile = true;
  bool _showTerritories = true;
  bool _permissionGranted = false;

  // Default center (Islamabad)
  static const _defaultCenter = LatLng(33.6844, 73.0479);

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await ref.read(locationPermissionProvider.future);
    if (mounted) {
      setState(() => _permissionGranted = granted);
    }
  }

  void _recenter() {
    final locAsync = ref.read(userLocationProvider);
    locAsync.whenData((loc) {
      if (loc.isValid) {
        _mapController.move(LatLng(loc.latitude, loc.longitude), 15.0);
      }
    });
  }

  void _onTerritoryTap(TerritoryModel territory) {
    TerritoryInfoSheet.show(context, territory);
  }

  @override
  Widget build(BuildContext context) {
    final locAsync = ref.watch(userLocationProvider);
    final territoriesAsync = ref.watch(territoriesProvider);
    final ownAreaAsync = ref.watch(ownTerritoryAreaProvider);

    // Resolve user position for map center
    final LatLng userPos = locAsync.when(
      data: (loc) =>
          loc.isValid ? LatLng(loc.latitude, loc.longitude) : _defaultCenter,
      loading: () => _defaultCenter,
      error: (_, __) => _defaultCenter,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ═══════════════ MAP ═══════════════════════════
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: 15.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              // ── Tile layer ────────────────────────────
              TileLayer(
                urlTemplate: _isLightTile ? _lightTileUrl : _satelliteTileUrl,
                userAgentPackageName: 'com.turf.app',
                retinaMode: true,
              ),

              // ── Territory polygons ────────────────────
              if (_showTerritories)
                territoriesAsync.when(
                  data: (list) => TerritoryOverlay(
                    territories: list,
                    onTerritoryTap: _onTerritoryTap,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

              // ── User location marker ──────────────────
              if (_permissionGranted)
                locAsync.when(
                  data: (loc) => loc.isValid
                      ? UserMarker(
                          position: LatLng(loc.latitude, loc.longitude),
                          accuracy: loc.accuracy,
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            ],
          ),

          // ═══════════════ GLASS OVERLAYS ═══════════════

          // ── Top-left: Rank Chip ──────────────────────
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 12,
            left: 16,
            child: _GlassPill(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 16, color: AppColors.goldAccent),
                const SizedBox(width: 6),
                Text(
                  '#12',
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Top-right: Territory Area Chip ───────────
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 12,
            right: 16,
            child: _GlassPill(
              children: [
                const Icon(Icons.pin_drop_rounded,
                    size: 16, color: AppColors.primaryTeal),
                const SizedBox(width: 6),
                Text(
                  ownAreaAsync.when(
                    data: (a) => '${a.toStringAsFixed(1)} km²',
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── Right: Map Controls ──────────────────────
          Positioned(
            right: 16,
            top: MediaQuery.viewPaddingOf(context).top + 68,
            child: MapControls(
              isLightTile: _isLightTile,
              showTerritories: _showTerritories,
              onRecenter: _recenter,
              onToggleTileStyle: () =>
                  setState(() => _isLightTile = !_isLightTile),
              onToggleTerritories: () =>
                  setState(() => _showTerritories = !_showTerritories),
            ),
          ),

          // ── Bottom: Today Stats Row ──────────────────
          Positioned(
            left: 48,
            right: 48,
            bottom: 188,
            child: _TodayStatsBar(),
          ),

          // ── Bottom: START RUN button ────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 112,
            child: Center(
              child: _StartRunButton(
                onTap: () => context.pushNamed('activeRun'),
              ),
            ),
          ),

          // ── Territory taps (GestureDetector overlay) ─
          if (_showTerritories)
            Positioned.fill(
              child: _TerritoryTapOverlay(
                territories: territoriesAsync.valueOrNull ?? [],
                mapController: _mapController,
                onTerritoryTap: _onTerritoryTap,
              ),
            ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Private Widgets
// ════════════════════════════════════════════════════════════

/// A small frosted-glass pill chip.
class _GlassPill extends StatelessWidget {
  final List<Widget> children;

  const _GlassPill({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

/// Today's stats bar — distance, runs, territory gained.
class _TodayStatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _miniStat('3.2 km', 'Distance'),
              _divider(),
              _miniStat('2', 'Runs'),
              _divider(),
              _miniStat('+0.08', 'Territory'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.textTertiary.withValues(alpha: 0.30),
    );
  }
}

/// Large teal "START RUN" pill button with shadow.
class _StartRunButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartRunButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryTeal.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Text(
              'START RUN',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Invisible overlay that detects taps on territory polygons.
class _TerritoryTapOverlay extends StatelessWidget {
  final List<TerritoryModel> territories;
  final MapController mapController;
  final void Function(TerritoryModel) onTerritoryTap;

  const _TerritoryTapOverlay({
    required this.territories,
    required this.mapController,
    required this.onTerritoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) {
        // Convert screen point → map coordinate
        final camera = mapController.camera;
        final tapLatLng = camera.pointToLatLng(
          math.Point(details.localPosition.dx, details.localPosition.dy),
        );

        // Check if tap is inside any territory polygon
        for (final t in territories) {
          if (_isPointInsidePolygon(tapLatLng, t.coordinates)) {
            onTerritoryTap(t);
            return;
          }
        }
      },
      child: const SizedBox.expand(),
    );
  }

  /// Simple ray-casting point-in-polygon test.
  bool _isPointInsidePolygon(LatLng point, List<LatLng> polygon) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if (((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}
