import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/features/activity/presentation/providers/live_activity_provider.dart';
import 'package:turf_app/features/map/widgets/territory_claim_celebration.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:confetti/confetti.dart';
import 'package:turf_app/features/map/presentation/providers/territories_provider.dart';
import 'package:turf_app/features/ai_coach/presentation/widgets/live_coaching_card.dart';
import 'package:turf_app/features/ai_coach/presentation/providers/ai_coach_provider.dart';

class LiveActivityScreen extends ConsumerStatefulWidget {
  const LiveActivityScreen({super.key});

  @override
  ConsumerState<LiveActivityScreen> createState() => _LiveActivityScreenState();
}

class _LiveActivityScreenState extends ConsumerState<LiveActivityScreen>
    with TickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  CircleAnnotationManager? _circleManager;
  int _claimedSourceCounter = 0;

  bool _isLocked = false;
  double _swipeProgress = 0.0;
  bool _mapGesturesEnabled = true;

  DateTime? _lastFlyTo;
  PolylineAnnotation? _routePolyline;

  Timer? _gestureLockTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late ConfettiController _confettiController;
  Timer? _radarTimer;
  CircleAnnotation? _radarCircle;
  double _radarProgress = 0.0; // 0.0 to 1.0

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _radarTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        _updateRadar();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _confettiController.dispose();
    _radarTimer?.cancel();
    _gestureLockTimer?.cancel();
    super.dispose();
  }

  // --- Rendering map stuff ---
  void _renderNewClaimedPolygon(List<Position> polygon) async {
    if (_mapboxMap == null || polygon.isEmpty) return;

    _claimedSourceCounter++;
    final sourceId = 'claimed_source_$_claimedSourceCounter';
    final fillLayerId = 'claimed_fill_$_claimedSourceCounter';
    final lineLayerId = 'claimed_line_$_claimedSourceCounter';

    final ring = polygon
        .map((p) => [p.lng.toDouble(), p.lat.toDouble()])
        .toList();
    if (ring.isNotEmpty &&
        (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add(List<double>.from(ring.first));
    }

    final geoJson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [ring],
          },
          'properties': {},
        },
      ],
    });

    try {
      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: sourceId, data: geoJson),
      );
      await _mapboxMap!.style.addLayer(
        FillLayer(
          id: fillLayerId,
          sourceId: sourceId,
          fillColor: const Color(0xFF00E676).value,
          fillOpacity: 0.35,
        ),
      );
      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: lineLayerId,
          sourceId: sourceId,
          lineColor: const Color(0xFF00E676).value,
          lineWidth: 2.0,
        ),
      );
    } catch (_) {}
  }

  void _updateMap(LiveActivityState state) async {
    if (_mapboxMap == null) return;

    if (state.routePoints.isNotEmpty) {
      final now = DateTime.now();
      if (!_mapGesturesEnabled &&
          (_lastFlyTo == null || now.difference(_lastFlyTo!).inSeconds >= 3)) {
        _lastFlyTo = now;
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: state.routePoints.last),
            zoom: 17.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }

      if (_polylineManager != null) {
        if (_routePolyline == null) {
          _routePolyline = await _polylineManager!.create(
            PolylineAnnotationOptions(
              geometry: LineString(coordinates: state.routePoints),
              lineColor: const Color(0xFF00E676).value,
              lineWidth: 5.0,
            ),
          );
        } else {
          _routePolyline!.geometry = LineString(coordinates: state.routePoints);
          await _polylineManager!.update(_routePolyline!);
        }
      }
    }

    if (_circleManager != null) {
      await _circleManager!.deleteAll();
      final List<CircleAnnotationOptions> circles = [];

      if (state.nearbyTerritory != null) {
        // Base territory circle
        circles.add(
          CircleAnnotationOptions(
            geometry: Point(coordinates: state.nearbyTerritory!.center),
            circleRadius: state.nearbyTerritory!.radiusMeters,
            circleColor: const Color(0xFF00E676).value,
            circleOpacity: 0.3,
            circleStrokeColor: const Color(0xFF00E676).value,
            circleStrokeWidth: 2.0,
          ),
        );

        // Radar circle will be created independently
      }

      if (state.routePoints.isNotEmpty) {
        circles.add(
          CircleAnnotationOptions(
            geometry: Point(coordinates: state.routePoints.last),
            circleRadius: 12.0,
            circleColor: const Color(0xFF00E676).value,
            circleStrokeColor: Colors.white.value,
            circleStrokeWidth: 3.0,
          ),
        );
      }

      if (circles.isNotEmpty) {
        await _circleManager!.createMulti(circles);
      }
    }
  }

  void _updateRadar() async {
    final state = ref.read(liveActivityProvider);
    if (_circleManager == null || state.nearbyTerritory == null) {
      if (_radarCircle != null) {
        await _circleManager?.delete(_radarCircle!);
        _radarCircle = null;
      }
      return;
    }

    _radarProgress +=
        0.025; // 50ms * 20 = 1000ms... wait 2 seconds = 40 frames, so 0.025 is 1 second. 0.0125 for 2 seconds.
    if (_radarProgress >= 1.0) _radarProgress = 0.0;

    final radius = 50.0 + (150.0 * _radarProgress);
    final opacity = 1.0 - _radarProgress;

    if (_radarCircle == null) {
      _radarCircle = await _circleManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: state.nearbyTerritory!.center),
          circleRadius: radius,
          circleColor: const Color(0xFF00E676).value,
          circleOpacity: opacity * 0.4,
          circleStrokeColor: const Color(0xFF00E676).value,
          circleStrokeWidth: 2.0,
          circleStrokeOpacity: opacity,
        ),
      );
    } else {
      _radarCircle!.circleRadius = radius;
      _radarCircle!.circleOpacity = opacity * 0.4;
      _radarCircle!.circleStrokeOpacity = opacity;
      await _circleManager!.update(_radarCircle!);
    }
  }

  void _showCancelDialog(LiveActivityNotifier notifier) {
    // Kept for backward compatibility if needed, but not used by Hold to Cancel
    Navigator.of(context).pop();
    context.go('/home/map');
  }

  void _showFinishDialog(BuildContext context, LiveActivityNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text(
          'Finish Activity?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to end your session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E676)),
                ),
              );
              try {
                final session = await notifier.stopAndSaveActivity();
                if (mounted) {
                  Navigator.pop(context); // pop loading
                  context.pushReplacement('/activity/summary', extra: session);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error saving session')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
            ),
            child: const Text('FINISH', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double speedKmh) {
    if (speedKmh <= 0) return "--:--";
    final paceMinPerKm = 60 / speedKmh;
    final m = paceMinPerKm.floor();
    final s = ((paceMinPerKm - m) * 60).round();
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  String _formatArea(double sqm) {
    if (sqm == 0) return "0 m²";
    if (sqm < 10000) {
      final formatted = sqm.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return "$formatted m²";
    } else {
      return "${(sqm / 10000).toStringAsFixed(1)} ha";
    }
  }

  Color _getBrandColor(String type) {
    switch (type) {
      case 'walk':
        return const Color(0xFF0A84FF);
      case 'cycle':
        return const Color(0xFFFF9500);
      default:
        return const Color(0xFF00E676);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveActivityProvider);
    final notifier = ref.read(liveActivityProvider.notifier);
    final isTtsEnabled = ref.watch(aiCoachProvider).isTtsEnabled;

    if (state.status == TrackingState.countdown) {
      return _CountdownScreen(onComplete: () => notifier.startActivity());
    }

    ref.listen(liveActivityProvider.select((s) => s.routePoints.length), (
      previous,
      next,
    ) {
      if (previous != null && next != previous) {
        _updateMap(ref.read(liveActivityProvider));
      }
    });

    ref.listen(liveActivityProvider.select((s) => s.nearbyTerritory), (
      previous,
      next,
    ) {
      if (previous != next) {
        _updateMap(ref.read(liveActivityProvider));
      }
    });

    ref.listen(liveActivityProvider.select((s) => s.claimedPolygons.length), (
      previous,
      next,
    ) {
      if (previous != null && next > previous) {
        _renderNewClaimedPolygon(
          ref.read(liveActivityProvider).claimedPolygons.last,
        );
      }
    });

    final isPaused = state.status == TrackingState.paused;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- FULL BLEED MAP ---
          Positioned.fill(
            child: MapWidget(
              key: const ValueKey('liveActivityMap'),
              cameraOptions: CameraOptions(
                zoom: 17.0,
                pitch: 45.0, // Pitched view as requested
              ),
              onMapCreated: (MapboxMap mapboxMap) async {
                _mapboxMap = mapboxMap;
                await mapboxMap.loadStyleURI(
                  'mapbox://styles/shoaib1965/cmqm2b0qd009m01s1h9773jnl',
                );
                mapboxMap.gestures.updateSettings(
                  GesturesSettings(
                    scrollEnabled: true,
                    pinchToZoomEnabled: true,
                    doubleTapToZoomInEnabled: true,
                    quickZoomEnabled: true,
                    pitchEnabled: true,
                    rotateEnabled: true,
                  ),
                );

                try {
                  final position = await geo.Geolocator.getCurrentPosition();
                  await mapboxMap.setCamera(
                    CameraOptions(
                      center: Point(
                        coordinates: Position(
                          position.longitude,
                          position.latitude,
                        ),
                      ),
                      zoom: 17.0,
                      pitch: 45.0,
                    ),
                  );
                } catch (_) {}

                final annMan = mapboxMap.annotations;
                _polylineManager = await annMan
                    .createPolylineAnnotationManager();
                _circleManager = await annMan.createCircleAnnotationManager();
                _updateMap(state);
                for (final poly in state.claimedPolygons) {
                  _renderNewClaimedPolygon(poly);
                }
              },
            ),
          ),

          // --- TOP LEFT: BACK / CANCEL BUTTON ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showCancelDialog(notifier);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),

          // --- TOP RIGHT: ACTIONS ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Group Icon
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Group run coming soon!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Mute/Unmute AI Coach Voice
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(aiCoachProvider.notifier).toggleTts();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isTtsEnabled ? Colors.white : const Color(0xFF1C1C1E),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isTtsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: isTtsEnabled ? Colors.black : Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Crosshair (Recenter)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _mapGesturesEnabled = false;
                      _mapboxMap?.gestures.updateSettings(
                        GesturesSettings(
                          scrollEnabled: false,
                          pinchToZoomEnabled: false,
                        ),
                      );
                    });
                    if (state.routePoints.isNotEmpty) {
                      _mapboxMap?.flyTo(
                        CameraOptions(
                          center: Point(coordinates: state.routePoints.last),
                          zoom: 17.0,
                          pitch: 45.0,
                        ),
                        MapAnimationOptions(duration: 1000),
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
                if (_mapGesturesEnabled)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Map Unlocked',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- DRAGGABLE WHITE STATS PANEL ---
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.70,
            snap: true,
            snapSizes: const [0.35, 0.70],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Drag Handle
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1D1D6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ROW 1: Area Claimed & GPS Status
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _formatArea(state.landClaimedSqm),
                                        style: const TextStyle(
                                          fontFamily: 'Space Grotesk',
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        "Capture in Progress",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: Color(0xFF8E8E93),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ROW 2: Primary Stats
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _LightStatCell(
                                    label: "Distance",
                                    value:
                                        "${state.distanceKm.toStringAsFixed(2)} km",
                                  ),
                                ),
                                Expanded(
                                  child: _LightStatCell(
                                    label: "Duration",
                                    value: _formatDuration(
                                      state.durationSeconds,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _LightStatCell(
                                    label: "Average pace",
                                    value: _formatPace(state.currentSpeedKmh),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // EXPANDED SECTION (Only visible when scrolled up)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Divider(color: Color(0xFFE5E5EA), height: 1),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _LightStatCell(
                                    label: "Calories burned",
                                    value: "${state.caloriesBurned}",
                                  ),
                                ),
                                Expanded(
                                  child: _LightStatCell(
                                    label: "Max Speed",
                                    value:
                                        "${state.maxSpeedKmh.toStringAsFixed(1)} km/h",
                                  ),
                                ),
                                Expanded(
                                  child: _LightStatCell(
                                    label: "Elevation gain",
                                    value:
                                        "${state.elevationGainM.toStringAsFixed(0)} m",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 100,
                            ), // Padding for the bottom
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // --- BOTTOM ACTIONS ---
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Left: Cancel Button (Opens Dialog)
                _CancelButton(
                  onCancel: () {
                    HapticFeedback.heavyImpact();
                    context.go('/home/map');
                  },
                ),

                // Center: Pause / Resume / Finish
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isPaused
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionPill(
                                label: "▶ Resume",
                                bgColor: Colors.black,
                                textColor: Colors.white,
                                onTap: () {
                                  HapticFeedback.heavyImpact();
                                  notifier.resumeActivity();
                                },
                              ),
                              const SizedBox(height: 12),
                              _ActionPill(
                                label: "⏹ Finish",
                                bgColor: const Color(0xFFFF3B30),
                                textColor: Colors.white,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _showFinishDialog(context, notifier);
                                },
                              ),
                            ],
                          )
                        : _ActionPill(
                            label: "⏸ Pause",
                            bgColor: Colors.black,
                            textColor: Colors.white,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              notifier.pauseActivity();
                            },
                          ),
                  ),
                ),

                // Right: Lock Button
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _isLocked = true);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Color(0xFFFFD60A),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Lock',
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- TERRITORY ALERT ---
          if (state.nearbyTerritory != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () async {
                  final territory = state.nearbyTerritory;
                  if (territory == null) return;
                  notifier.clearNearbyTerritory();

                  try {
                    await ref
                        .read(territoryRepositoryProvider)
                        .captureTerritory(territory.id, territory.xpValue);

                    _confettiController.play();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🏴 Territory Captured! +${territory.xpValue} XP',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: const Color(0xFF00E676),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Territory already captured!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Color(0xFFFF453A),
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Text("🏴", style: TextStyle(fontSize: 20)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Territory Nearby! Tap to Capture",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // --- AI LIVE COACHING CARD ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 72,
            child: const LiveCoachingCard(),
          ),

          // --- CONFETTI ---
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 8,
              colors: const [
                Color(0xFF00E676),
                Colors.white,
                Color(0xFF0A84FF),
                Color(0xFFFFD60A),
              ],
            ),
          ),

          // --- LOCK OVERLAY ---
          if (_isLocked)
            Positioned.fill(
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(
                    () => _swipeProgress =
                        (details.localPosition.dx /
                                MediaQuery.of(context).size.width)
                            .clamp(0.0, 1.0),
                  );
                },
                onHorizontalDragEnd: (details) {
                  if (_swipeProgress > 0.7) {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _isLocked = false;
                      _swipeProgress = 0;
                    });
                  } else {
                    setState(() => _swipeProgress = 0);
                  }
                },
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Screen Locked",
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 10.0),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeInOut,
                                  builder: (context, val, child) {
                                    // Use sine wave for bouncing effect
                                    final bounce = math.sin(val * math.pi) * 8;
                                    return Transform.translate(
                                      offset: Offset(bounce, 0),
                                      child: child,
                                    );
                                  },
                                  onEnd: () {
                                    // Hack to keep it looping by letting builder rebuild
                                    // In a real app we'd use AnimationController, but TweenAnimationBuilder is fine here if we don't strictly loop, or we can use the main controller. Let's just do a subtle static icon if it's too complex.
                                  },
                                  child: const Icon(
                                    Icons.keyboard_double_arrow_right_rounded,
                                    color: Color(0xFF8E8E93),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Swipe right to unlock",
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          height: 3,
                          width:
                              MediaQuery.of(context).size.width *
                              _swipeProgress,
                          color: const Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (state.lastClaimAreaSqm != null)
            TerritoryClaimCelebration(
              areaSqm: state.lastClaimAreaSqm!,
              onDismiss: () => notifier.clearLastClaim(),
            ),
        ],
      ),
    );
  }
}

class _LightStatCell extends StatelessWidget {
  final String label;
  final String value;

  const _LightStatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Space Grotesk',
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CountdownScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const _CountdownScreen({required this.onComplete});

  @override
  State<_CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<_CountdownScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  int _currentNumber = 3;
  bool _showGo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_controller);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4)),
    );

    _runCountdown();
  }

  Future<void> _runCountdown() async {
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _currentNumber = i);
      HapticFeedback.heavyImpact();
      _controller.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (!mounted) return;
    setState(() => _showGo = true);
    HapticFeedback.heavyImpact();
    _controller.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Text(
                  _showGo ? "GO!" : _currentNumber.toString(),
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: _showGo ? const Color(0xFF00E676) : Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback onCancel;
  const _CancelButton({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => _CancelDialog(onCancel: onCancel),
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF2C2C2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: Color(0xFFFF453A),
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cancel',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 10),
        ),
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  final VoidCallback onCancel;
  const _CancelDialog({required this.onCancel});

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _cancelController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _cancelController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    );
    _cancelController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pop();
        widget.onCancel();
      }
    });
  }

  @override
  void dispose() {
    _cancelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            // Top highlight for 3D effect
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 0,
              spreadRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Color(0xFFFF453A),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancel Activity?',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will discard all progress and territory captured during this session.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 32),
            
            // 3D Hold to Cancel Button
            GestureDetector(
              onTapDown: (_) {
                setState(() => _isPressed = true);
                HapticFeedback.lightImpact();
                _cancelController.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _cancelController.reverse();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
                _cancelController.reverse();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                transform: Matrix4.translationValues(0, _isPressed ? 6 : 0, 0),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isPressed
                        ? [] // Pressed state has no shadow
                        : [
                            // 3D bottom shadow
                            const BoxShadow(
                              color: Color(0xFF141414),
                              offset: Offset(0, 6),
                              blurRadius: 0,
                            ),
                            // Top highlight
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              offset: const Offset(0, -1),
                              blurRadius: 0,
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Fill animation
                        AnimatedBuilder(
                          animation: _cancelController,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor: _cancelController.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Text overlay
                        Center(
                          child: Text(
                            'Hold to Cancel',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Add spacing to compensate for the 3D button's shadow when not pressed
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              height: _isPressed ? 16 + 6 : 16, // +6 to match shadow offset
            ),
            
            // Keep Going Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                minimumSize: const ui.Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Keep Going',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
