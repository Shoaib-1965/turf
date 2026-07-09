import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:turf_app/core/utils/polyline_codec.dart';
import 'package:turf_app/core/widgets/user_avatar.dart';
import 'package:turf_app/features/activity/domain/models/feed_activity.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityDetailScreen extends StatelessWidget {
  final FeedActivity activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final routePoints = PolylineCodec.decode(activity.session.routePolyline);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Activity Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  UserAvatar(
                    size: 48,
                    avatarUrl: activity.profile.avatarUrl,
                    fullName: activity.profile.fullName,
                    terraColor: activity.profile.terraColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.profile.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(timeago.format(activity.session.endedAt), style: const TextStyle(color: Colors.white54, fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTypeColor(activity.session.activityType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.session.activityType.toUpperCase(),
                      style: TextStyle(color: _getTypeColor(activity.session.activityType), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            // Map
            if (routePoints.isNotEmpty)
              SizedBox(
                height: 300,
                child: MapWidget(
                  key: const ValueKey("detailMap"),
                  onMapCreated: (MapboxMap mapboxMap) async {
                    mapboxMap.loadStyleURI('mapbox://styles/shoaib1965/cmqm2b0qd009m01s1h9773jnl');
                    if (routePoints.isNotEmpty) {
                      final manager = await mapboxMap.annotations.createPolylineAnnotationManager();
                      await manager.create(PolylineAnnotationOptions(
                        geometry: LineString(coordinates: routePoints),
                        lineColor: const Color(0xFF00E676).value,
                        lineWidth: 5.0,
                      ));
                      
                      try {
                        final camera = await mapboxMap.cameraForCoordinates(
                          routePoints.map((p) => Point(coordinates: p)).toList(),
                          MbxEdgeInsets(top: 32, left: 32, bottom: 32, right: 32),
                          null, null,
                        );
                        mapboxMap.setCamera(camera);
                      } catch (e) {
                        mapboxMap.setCamera(CameraOptions(
                          center: Point(coordinates: routePoints.first),
                          zoom: 14,
                        ));
                      }
                    }
                  },
                ),
              ),
              
            const SizedBox(height: 24),
            
            // Main Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    activity.session.distanceKm.toStringAsFixed(2),
                    style: const TextStyle(fontFamily: 'Space Grotesk', fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0, left: 8),
                    child: Text('km', style: TextStyle(color: Colors.white54, fontSize: 20)),
                  ),
                ],
              ),
            ),
            
            // Grid of Stats
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DetailStat(label: 'Duration', value: _formatDuration(activity.session.durationSeconds)),
                      _DetailStat(label: 'Pace', value: _formatPace(activity.session.distanceKm, activity.session.durationSeconds)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DetailStat(label: 'Avg Speed', value: '${activity.session.avgSpeedKmh.toStringAsFixed(1)} km/h'),
                      _DetailStat(label: 'Calories', value: '${activity.session.caloriesBurned}'),
                    ],
                  ),
                  if (activity.session.xpEarned > 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF00E676).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('+${activity.session.xpEarned} XP Earned', style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'run': return const Color(0xFF00E676);
      case 'walk': return const Color(0xFF00B0FF);
      case 'cycle': return const Color(0xFFFF9100);
      default: return const Color(0xFF00E676);
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Space Grotesk')),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}

