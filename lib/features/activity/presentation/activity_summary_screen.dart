import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' if (dart.library.html) 'package:turf_app/core/utils/platform_utils.dart';
import 'package:turf_app/features/map/widgets/map_view.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:turf_app/features/activity/domain/models/activity_session.dart';
import 'package:turf_app/core/utils/polyline_codec.dart';

class ActivitySummaryScreen extends StatefulWidget {
  final ActivitySession session;

  const ActivitySummaryScreen({super.key, required this.session});

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen> {
  late ConfettiController _confettiController;
  late List<Position> _routePoints;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _routePoints = PolylineCodec.decode(widget.session.routePolyline);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.session.xpEarned > 0) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Activity Complete',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Map thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 250,
                        child: TurfMapView(
                          key: const ValueKey("summaryMap"),
                          onMapCreated: (MapboxMap mapboxMap) async {
                            mapboxMap.loadStyleURI(
                              'mapbox://styles/shoaib1965/cmqm2b0qd009m01s1h9773jnl',
                            );

                            // disable interactions
                            mapboxMap.gestures.updateSettings(
                              GesturesSettings(
                                scrollEnabled: false,
                                pinchToZoomEnabled: false,
                                doubleTapToZoomInEnabled: false,
                                doubleTouchToZoomOutEnabled: false,
                                quickZoomEnabled: false,
                                pitchEnabled: false,
                                rotateEnabled: false,
                              ),
                            );

                            if (_routePoints.isNotEmpty) {
                              final manager = await mapboxMap.annotations
                                  .createPolylineAnnotationManager();
                              await manager.create(
                                PolylineAnnotationOptions(
                                  geometry: LineString(
                                    coordinates: _routePoints,
                                  ),
                                  lineColor: const Color(0xFF00E676).value,
                                  lineWidth: 4.0,
                                ),
                              );

                              try {
                                final camera = await mapboxMap
                                    .cameraForCoordinates(
                                      _routePoints
                                          .map((p) => Point(coordinates: p))
                                          .toList(),
                                      MbxEdgeInsets(
                                        top: 32,
                                        left: 32,
                                        bottom: 32,
                                        right: 32,
                                      ),
                                      null,
                                      null,
                                    );
                                mapboxMap.setCamera(camera);
                              } catch (e) {
                                mapboxMap.setCamera(
                                  CameraOptions(
                                    center: Point(
                                      coordinates: _routePoints.first,
                                    ),
                                    zoom: 14,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Grid
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.session.distanceKm.toStringAsFixed(2)} km',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Space Grotesk',
                              color: Color(0xFF00E676),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryStat(
                                label: 'Duration',
                                value: _formatDuration(
                                  widget.session.durationSeconds,
                                ),
                              ),
                              _SummaryStat(
                                label: 'Avg Pace',
                                value: _formatPace(
                                  widget.session.distanceKm,
                                  widget.session.durationSeconds,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SummaryStat(
                                label: 'Avg Speed',
                                value:
                                    '${widget.session.avgSpeedKmh.toStringAsFixed(1)} km/h',
                              ),
                              _SummaryStat(
                                label: 'Calories',
                                value: '${widget.session.caloriesBurned}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${widget.session.xpEarned} XP',
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Handle share
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'SHARE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.go('/home/map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E676),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'DONE',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFF00E676), Colors.white, Colors.yellow],
            ),
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

  String _formatPace(double distanceKm, int durationSeconds) {
    if (distanceKm == 0) return "0:00";
    final pace = (durationSeconds / 60) / distanceKm;
    final mins = pace.toInt();
    final secs = ((pace % 1) * 60).toInt();
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Space Grotesk',
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }
}
