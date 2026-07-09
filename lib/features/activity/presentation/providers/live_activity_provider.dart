import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_app/core/services/background_tracking_service.dart';
import 'package:turf_app/core/utils/polyline_codec.dart';
import 'package:turf_app/features/activity/data/activity_repository.dart';
import 'package:turf_app/features/activity/domain/models/activity_session.dart';
import 'package:turf_app/features/activity/domain/models/location_ping.dart';
import 'package:turf_app/features/activity/utils/loop_detection_service.dart';
import 'package:turf_app/features/map/data/territory_claim_repository.dart';
import 'package:turf_app/features/map/presentation/providers/location_provider.dart';
import 'package:turf_app/features/map/domain/models/territory.dart';
import 'package:turf_app/features/map/presentation/providers/territories_provider.dart';
import 'package:turf_app/features/activity/presentation/providers/activity_feed_provider.dart';
import 'package:turf_app/features/profile/presentation/providers/profile_provider.dart';

enum TrackingState { idle, countdown, active, paused, finished }

class LiveActivityState {
  final TrackingState status;
  final String activityType; // 'run', 'walk', 'cycle'
  final int durationSeconds;
  final double distanceKm;
  final double currentSpeedKmh;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int caloriesBurned;
  final double elevationGainM;
  final List<mapbox.Position> routePoints;
  final List<LocationPing> pendingPings;
  final Territory? nearbyTerritory;

  // Organic territory claiming
  final List<List<mapbox.Position>>
  claimedPolygons; // Polygons claimed this session
  final double landClaimedSqm; // Total area claimed this session
  final double?
  lastClaimAreaSqm; // Area of the most recent claim (for celebration)

  LiveActivityState({
    this.status = TrackingState.idle,
    this.activityType = 'run',
    this.durationSeconds = 0,
    this.distanceKm = 0.0,
    this.currentSpeedKmh = 0.0,
    this.avgSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.caloriesBurned = 0,
    this.elevationGainM = 0.0,
    this.routePoints = const [],
    this.pendingPings = const [],
    this.nearbyTerritory,
    this.claimedPolygons = const [],
    this.landClaimedSqm = 0.0,
    this.lastClaimAreaSqm,
  });

  LiveActivityState copyWith({
    TrackingState? status,
    String? activityType,
    int? durationSeconds,
    double? distanceKm,
    double? currentSpeedKmh,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    int? caloriesBurned,
    double? elevationGainM,
    List<mapbox.Position>? routePoints,
    List<LocationPing>? pendingPings,
    Territory? nearbyTerritory,
    List<List<mapbox.Position>>? claimedPolygons,
    double? landClaimedSqm,
    double? lastClaimAreaSqm,
  }) {
    return LiveActivityState(
      status: status ?? this.status,
      activityType: activityType ?? this.activityType,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceKm: distanceKm ?? this.distanceKm,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      elevationGainM: elevationGainM ?? this.elevationGainM,
      routePoints: routePoints ?? this.routePoints,
      pendingPings: pendingPings ?? this.pendingPings,
      nearbyTerritory: nearbyTerritory, // Can be null
      claimedPolygons: claimedPolygons ?? this.claimedPolygons,
      landClaimedSqm: landClaimedSqm ?? this.landClaimedSqm,
      lastClaimAreaSqm: lastClaimAreaSqm,
    );
  }
}

final activityRepositoryProvider = Provider((ref) => ActivityRepository());

class LiveActivityNotifier extends Notifier<LiveActivityState> {
  Timer? _timer;
  Timer? _pingTimer;
  Timer? _territoryTimer;
  StreamSubscription<Position>? _positionSub;
  DateTime? _startedAt;

  final List<double> _speedBuffer = [];
  final List<double> _altitudeBuffer = [];
  double? _lastMedianAltitude;
  double _accumulatedCalories = 0.0;

  @override
  LiveActivityState build() {
    ref.onDispose(() {
      _cleanup();
    });
    return LiveActivityState();
  }

  void _cleanup() {
    _timer?.cancel();
    _pingTimer?.cancel();
    _territoryTimer?.cancel();
    _positionSub?.cancel();
    BackgroundTrackingService.stopTrackingTask();
  }

  void setActivityType(String type) {
    state = state.copyWith(activityType: type);
  }

  void startCountdown() {
    state = state.copyWith(status: TrackingState.countdown);
  }

  void startActivity() {
    if (state.status == TrackingState.active || state.status == TrackingState.paused) {
      return; // Already started
    }
    
    _cleanup(); // Ensure no dangling timers exist

    _startedAt = DateTime.now();
    state = state.copyWith(status: TrackingState.active);
    BackgroundTrackingService.startTrackingTask();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TrackingState.active) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
        if (state.durationSeconds % 10 == 0) {
          _updateCalories();
        }
        if (state.durationSeconds % 5 == 0) {
          _updateNotification();
        }
      }
    });

    _pingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (state.pendingPings.isNotEmpty &&
          state.status == TrackingState.active) {
        final repo = ref.read(activityRepositoryProvider);
        repo.batchInsertLocationPings(List.from(state.pendingPings));
        state = state.copyWith(pendingPings: []);
      }
    });

    _territoryTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (state.status == TrackingState.active &&
          state.routePoints.isNotEmpty) {
        _checkForNearbyTerritories(state.routePoints.last);
      }
    });

    _startLocationUpdates();
  }

  Future<void> _startLocationUpdates() async {
    final locationService = ref.read(locationServiceProvider);

    final hasPermission = await locationService.handlePermission();
    if (!hasPermission) return;

    _positionSub = locationService.getPositionStream().listen((pos) {
      if (state.status != TrackingState.active) return;

      final newPoint = mapbox.Position(pos.longitude, pos.latitude);
      final updatedPoints = List<mapbox.Position>.from(state.routePoints)
        ..add(newPoint);

      double addedDistance = 0.0;
      if (state.routePoints.isNotEmpty) {
        final lastPoint = state.routePoints.last;
        addedDistance =
            Geolocator.distanceBetween(
              lastPoint.lat.toDouble(),
              lastPoint.lng.toDouble(),
              newPoint.lat.toDouble(),
              newPoint.lng.toDouble(),
            ) /
            1000.0; // km
      }

      final rawSpeedKmh = pos.speed * 3.6;
      _speedBuffer.add(rawSpeedKmh);
      if (_speedBuffer.length > 5) _speedBuffer.removeAt(0);
      final smoothedSpeedKmh = _speedBuffer.isEmpty
          ? 0.0
          : _speedBuffer.reduce((a, b) => a + b) / _speedBuffer.length;

      final newDistance = state.distanceKm + addedDistance;
      final avgSpeed = state.durationSeconds > 0
          ? (newDistance / (state.durationSeconds / 3600.0))
          : 0.0;
      final maxSpeed = smoothedSpeedKmh > state.maxSpeedKmh
          ? smoothedSpeedKmh
          : state.maxSpeedKmh;

      double newElevationGain = state.elevationGainM;
      _altitudeBuffer.add(pos.altitude);
      if (_altitudeBuffer.length > 3) _altitudeBuffer.removeAt(0);
      if (_altitudeBuffer.length == 3) {
        final sortedAlt = List<double>.from(_altitudeBuffer)..sort();
        final medianAlt = sortedAlt[1];
        if (_lastMedianAltitude != null &&
            medianAlt - _lastMedianAltitude! > 0.5) {
          newElevationGain += (medianAlt - _lastMedianAltitude!);
        }
        _lastMedianAltitude = medianAlt;
      }

      final ping = LocationPing(
        sessionId:
            'temp_session_id', // Replaced upon full save if needed, or kept empty
        userId: Supabase.instance.client.auth.currentUser!.id,
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        speedMs: pos.speed,
        heading: pos.heading,
        recordedAt: DateTime.now(),
      );

      state = state.copyWith(
        routePoints: updatedPoints,
        distanceKm: newDistance,
        currentSpeedKmh: smoothedSpeedKmh,
        avgSpeedKmh: avgSpeed,
        maxSpeedKmh: maxSpeed,
        elevationGainM: newElevationGain,
        pendingPings: List.from(state.pendingPings)..add(ping),
      );

      // --- Loop detection for organic territory claiming ---
      _checkForLoopClaim(updatedPoints);
    });
  }

  void _updateCalories() {
    double met = 0;
    final speed = state.currentSpeedKmh;

    if (state.activityType == 'run') {
      if (speed < 8) {
        met = 8.3;
      } else if (speed <= 11)
        met = 11.0;
      else
        met = 14.5;
    } else if (state.activityType == 'walk') {
      if (speed < 4) {
        met = 2.8;
      } else if (speed <= 6)
        met = 3.5;
      else
        met = 4.3;
    } else if (state.activityType == 'cycle') {
      if (speed < 16) {
        met = 6.0;
      } else if (speed <= 20)
        met = 8.0;
      else
        met = 10.0;
    }

    final profile = ref.read(profileProvider).value;
    double weightKg = profile?.weightKg ?? 70.0;

    // Called every 10 seconds, calculate for that interval
    _accumulatedCalories += (met * weightKg * (10.0 / 3600.0));

    state = state.copyWith(caloriesBurned: _accumulatedCalories.round());
  }

  void _updateNotification() {
    final pace = state.distanceKm > 0
        ? (state.durationSeconds / 60) / state.distanceKm
        : 0.0;
    final paceStr =
        "${pace.toInt()}:${((pace % 1) * 60).toInt().toString().padLeft(2, '0')} /km";
    BackgroundTrackingService.showTrackingNotification(
      "TURF - Tracking your ${state.activityType}",
      "${state.distanceKm.toStringAsFixed(2)} km | $paceStr",
    );
  }

  void _checkForNearbyTerritories(mapbox.Position currentLoc) {
    // get current territories
    final territories = ref.read(territoriesProvider).value ?? [];
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    for (var t in territories) {
      if (t.ownerId != currentUserId) {
        final dist = Geolocator.distanceBetween(
          currentLoc.lat.toDouble(),
          currentLoc.lng.toDouble(),
          t.center.lat.toDouble(),
          t.center.lng.toDouble(),
        );
        if (dist <= 200) {
          state = state.copyWith(nearbyTerritory: t);
          return; // just show one
        }
      }
    }
    state = state.copyWith(nearbyTerritory: null); // Clear if none
  }

  /// Core loop detection — called after every GPS update.
  void _checkForLoopClaim(List<mapbox.Position> currentPoints) {
    try {
      final loop = LoopDetectionService.checkForLoop(currentPoints);
      if (loop == null) return;

      // Optimistic UI update: add the polygon immediately
      final updatedPolygons = List<List<mapbox.Position>>.from(
        state.claimedPolygons,
      )..add(loop.polygon);
      final updatedArea = state.landClaimedSqm + loop.areaSqm;

      state = state.copyWith(
        claimedPolygons: updatedPolygons,
        landClaimedSqm: updatedArea,
        lastClaimAreaSqm: loop.areaSqm,
      );

      // Persist to Supabase in background (don't block UI)
      _persistClaim(loop);
    } catch (_) {
      // Don't crash the tracking if detection fails
    }
  }

  Future<void> _persistClaim(DetectedLoop loop) async {
    try {
      final repo = ref.read(territoryClaimRepositoryProvider);
      // We need a session_id. Since the session isn't saved yet during tracking,
      // we use 'temp' and update later, OR we can pass a placeholder.
      // For now, the RLS check requires a valid session, so we save a preliminary
      // session and use its ID. Alternatively, we can relax the constraint.
      // Simplest approach: save claim without session_id if column is nullable.
      await repo.insertClaim(
        sessionId: '', // Will be updated when session is saved
        polygon: loop.polygon,
      );
    } catch (_) {
      // Claim will only exist locally (optimistic) if server fails
    }
  }

  /// Clear the last claim celebration (called after animation completes).
  void clearLastClaim() {
    state = state.copyWith(lastClaimAreaSqm: null);
  }

  void clearNearbyTerritory() {
    // Force clear the territory state if we close it
    state = state.copyWith(nearbyTerritory: null);
  }

  void pauseActivity() {
    state = state.copyWith(status: TrackingState.paused);
    BackgroundTrackingService.showTrackingNotification(
      "TURF - Paused",
      "Activity is paused",
    );
  }

  void resumeActivity() {
    state = state.copyWith(status: TrackingState.active);
  }

  Future<ActivitySession> stopAndSaveActivity() async {
    _cleanup();
    state = state.copyWith(status: TrackingState.finished);

    // flush pings
    if (state.pendingPings.isNotEmpty) {
      ref
          .read(activityRepositoryProvider)
          .batchInsertLocationPings(state.pendingPings);
    }

    final polyline = PolylineCodec.encode(state.routePoints);
    int xpEarned = (state.distanceKm * 10).round();
    // Add pace bonus logic later

    final session = ActivitySession(
      userId: Supabase.instance.client.auth.currentUser!.id,
      activityType: state.activityType,
      startedAt: _startedAt ?? DateTime.now(),
      endedAt: DateTime.now(),
      durationSeconds: state.durationSeconds,
      distanceKm: state.distanceKm,
      avgSpeedKmh: state.avgSpeedKmh,
      maxSpeedKmh: state.maxSpeedKmh,
      caloriesBurned: state.caloriesBurned,
      elevationGainM: state.elevationGainM,
      routePolyline: polyline,
      xpEarned: xpEarned,
    );

    await ref.read(activityRepositoryProvider).saveActivitySession(session);

    // Refresh the feed immediately so it shows up in "My Activities"
    ref.read(activityFeedProvider.notifier).loadInitialData();

    return session;
  }
}

final liveActivityProvider =
    NotifierProvider<LiveActivityNotifier, LiveActivityState>(() {
      return LiveActivityNotifier();
    });
