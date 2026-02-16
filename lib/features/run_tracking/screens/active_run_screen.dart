import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/territory_service.dart';
import '../../map/providers/location_provider.dart';
import '../../map/widgets/user_marker.dart';
import '../providers/run_provider.dart';
import '../widgets/capture_toast.dart';
import '../widgets/run_control_bar.dart';
import '../widgets/run_stats_hud.dart';
import '../widgets/stop_confirmation_modal.dart';

const _lightTileUrl =
    'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';

class ActiveRunScreen extends ConsumerStatefulWidget {
  const ActiveRunScreen({super.key});

  @override
  ConsumerState<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends ConsumerState<ActiveRunScreen> {
  final MapController _mapController = MapController();
  Timer? _captureTimer;
  List<LatLng> _capturePolygon = [];
  bool _showCaptureToast = false;
  String _captureToastMessage = '';
  bool _captureToastStolen = false;
  int _captureCount = 0;

  @override
  void initState() {
    super.initState();
    // Keep screen on during run
    WakelockPlus.enable();

    // Start the run
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(runProvider.notifier).startRun();
      _startCaptureTimer();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _captureTimer?.cancel();
    super.dispose();
  }

  void _startCaptureTimer() {
    _captureTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateCapturePolygon();
    });
  }

  void _updateCapturePolygon() {
    final runState = ref.read(runProvider);
    if (runState.routePoints.length < 2) return;

    final polygon = TerritoryService.bufferRoute(runState.routePoints);
    setState(() {
      _capturePolygon = polygon;
      _captureCount++;
    });

    // Show capture feedback
    final area = runState.territoryCapturedKm2;
    _showCaptureFeedback('+${area.toStringAsFixed(2)} km² claimed! 🏴');

    // Simulate stolen territory after 60s (2 capture cycles)
    if (_captureCount == 2) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          HapticFeedback.heavyImpact();
          _showCaptureFeedback(
            '⚠️ ShadowRunner stole 0.3 km²!',
            stolen: true,
          );
        }
      });
    }
  }

  void _showCaptureFeedback(String message, {bool stolen = false}) {
    setState(() {
      _showCaptureToast = true;
      _captureToastMessage = message;
      _captureToastStolen = stolen;
    });
  }

  Future<void> _handleStop() async {
    final runState = ref.read(runProvider);
    final confirmed = await StopConfirmationModal.show(
      context,
      distance: runState.distanceKm.toStringAsFixed(1),
      territory: runState.territoryCapturedKm2.toStringAsFixed(1),
    );
    if (confirmed && mounted) {
      ref.read(runProvider.notifier).stopRun();
      // Navigate to summary — use a generated run ID
      final runId = DateTime.now().millisecondsSinceEpoch.toString();
      context.pushReplacementNamed('runSummary', pathParameters: {
        'runId': runId,
      });
    }
  }

  void _handlePause() {
    final runState = ref.read(runProvider);
    if (runState.status == RunStatus.paused) {
      ref.read(runProvider.notifier).resumeRun();
    } else {
      ref.read(runProvider.notifier).pauseRun();
    }
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final locAsync = ref.watch(userLocationProvider);

    // Feed GPS points into the run notifier
    locAsync.whenData((loc) {
      if (loc.isValid && runState.status == RunStatus.active) {
        ref
            .read(runProvider.notifier)
            .addPoint(LatLng(loc.latitude, loc.longitude));
      }
    });

    // User position for map centering
    final LatLng userPos = locAsync.when(
      data: (loc) => loc.isValid
          ? LatLng(loc.latitude, loc.longitude)
          : const LatLng(33.6844, 73.0479),
      loading: () => const LatLng(33.6844, 73.0479),
      error: (_, __) => const LatLng(33.6844, 73.0479),
    );

    // Auto-follow camera
    if (runState.status == RunStatus.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(userPos, _mapController.camera.zoom);
        } catch (_) {
          // MapController not ready yet
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleStop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ═══════════════ MAP ═══════════════════════════
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userPos,
                initialZoom: 16.0,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                // ── Tile layer ──────────────────────────────
                TileLayer(
                  urlTemplate: _lightTileUrl,
                  userAgentPackageName: 'com.turf.app',
                  retinaMode: true,
                ),

                // ── Territory capture preview polygon ───────
                if (_capturePolygon.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _capturePolygon,
                        color: AppColors.primaryTeal.withValues(alpha: 0.20),
                        borderColor:
                            AppColors.primaryTeal.withValues(alpha: 0.50),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  ),

                // ── Live route polyline ─────────────────────
                if (runState.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: runState.routePoints,
                        color: AppColors.primaryTeal,
                        strokeWidth: 4.5,
                      ),
                    ],
                  ),

                // ── User marker ─────────────────────────────
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

            // ── Top: Control bar ─────────────────────────
            Positioned(
              top: MediaQuery.viewPaddingOf(context).top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: RunControlBar(
                  duration: runState.durationFormatted,
                  isPaused: runState.status == RunStatus.paused,
                  onPauseTap: _handlePause,
                  onStopTap: _handleStop,
                ),
              ),
            ),

            // ── Bottom: Stats HUD ────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: RunStatsHud(
                pace: runState.currentPaceFormatted,
                distance: runState.distanceKm.toStringAsFixed(1),
                duration: runState.durationFormatted,
                territory:
                    '${runState.territoryCapturedKm2.toStringAsFixed(1)} km²',
                calories: runState.calories.toString(),
              ),
            ),

            // ── Capture toast ────────────────────────────
            if (_showCaptureToast)
              Positioned(
                top: MediaQuery.viewPaddingOf(context).top + 80,
                left: 40,
                right: 40,
                child: Center(
                  child: CaptureToast(
                    message: _captureToastMessage,
                    isStolen: _captureToastStolen,
                    onDismissed: () {
                      if (mounted) {
                        setState(() => _showCaptureToast = false);
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
