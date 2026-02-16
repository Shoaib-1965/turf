import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/geo_utils.dart';

// ── Run status enum ────────────────────────────────────────
enum RunStatus { idle, active, paused, completed }

// ── Run state ──────────────────────────────────────────────
class RunState {
  final RunStatus status;
  final DateTime? startTime;
  final Duration elapsed;
  final double distanceKm;
  final int avgPaceSecPerKm;
  final int currentPaceSecPerKm;
  final double territoryCapturedKm2;
  final List<LatLng> routePoints;
  final int calories;

  const RunState({
    this.status = RunStatus.idle,
    this.startTime,
    this.elapsed = Duration.zero,
    this.distanceKm = 0,
    this.avgPaceSecPerKm = 0,
    this.currentPaceSecPerKm = 0,
    this.territoryCapturedKm2 = 0,
    this.routePoints = const [],
    this.calories = 0,
  });

  RunState copyWith({
    RunStatus? status,
    DateTime? startTime,
    Duration? elapsed,
    double? distanceKm,
    int? avgPaceSecPerKm,
    int? currentPaceSecPerKm,
    double? territoryCapturedKm2,
    List<LatLng>? routePoints,
    int? calories,
  }) {
    return RunState(
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      distanceKm: distanceKm ?? this.distanceKm,
      avgPaceSecPerKm: avgPaceSecPerKm ?? this.avgPaceSecPerKm,
      currentPaceSecPerKm: currentPaceSecPerKm ?? this.currentPaceSecPerKm,
      territoryCapturedKm2: territoryCapturedKm2 ?? this.territoryCapturedKm2,
      routePoints: routePoints ?? this.routePoints,
      calories: calories ?? this.calories,
    );
  }

  /// Formatted pace string, e.g. "5:24".
  String get avgPaceFormatted {
    if (avgPaceSecPerKm <= 0) return '--:--';
    final m = avgPaceSecPerKm ~/ 60;
    final s = avgPaceSecPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get currentPaceFormatted {
    if (currentPaceSecPerKm <= 0) return '--:--';
    final m = currentPaceSecPerKm ~/ 60;
    final s = currentPaceSecPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Formatted duration, e.g. "24:35".
  String get durationFormatted {
    final totalSec = elapsed.inSeconds;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── RunNotifier ────────────────────────────────────────────
class RunNotifier extends StateNotifier<RunState> {
  RunNotifier() : super(const RunState());

  Timer? _ticker;
  DateTime? _pauseTime;
  Duration _pauseAccum = Duration.zero;

  // Last 5 points for current pace smoothing
  final List<_TimedPoint> _recentPoints = [];

  void startRun() {
    final now = DateTime.now();
    state = RunState(
      status: RunStatus.active,
      startTime: now,
    );
    _pauseAccum = Duration.zero;
    _recentPoints.clear();
    _startTicker();
  }

  void pauseRun() {
    _ticker?.cancel();
    _pauseTime = DateTime.now();
    state = state.copyWith(status: RunStatus.paused);
  }

  void resumeRun() {
    if (_pauseTime != null) {
      _pauseAccum += DateTime.now().difference(_pauseTime!);
      _pauseTime = null;
    }
    state = state.copyWith(status: RunStatus.active);
    _startTicker();
  }

  RunState stopRun() {
    _ticker?.cancel();
    state = state.copyWith(status: RunStatus.completed);
    return state;
  }

  void addPoint(LatLng point) {
    if (state.status != RunStatus.active) return;

    final points = [...state.routePoints, point];
    double dist = state.distanceKm;

    if (state.routePoints.isNotEmpty) {
      final prev = state.routePoints.last;
      final segmentM = GeoUtils.distanceInMeters(
        prev.latitude,
        prev.longitude,
        point.latitude,
        point.longitude,
      );
      dist += segmentM / 1000;
    }

    // ── Current pace (last 5 points) ───────────────────
    _recentPoints.add(_TimedPoint(point, DateTime.now()));
    if (_recentPoints.length > 5) _recentPoints.removeAt(0);

    int curPace = 0;
    if (_recentPoints.length >= 2) {
      final first = _recentPoints.first;
      final last = _recentPoints.last;
      final recentDist = GeoUtils.distanceInMeters(
            first.point.latitude,
            first.point.longitude,
            last.point.latitude,
            last.point.longitude,
          ) /
          1000;
      final recentSec = last.time.difference(first.time).inSeconds.toDouble();
      if (recentDist > 0.001) {
        curPace = (recentSec / recentDist).round();
      }
    }

    // ── Average pace ─────────────────────────────────────
    int avgPace = 0;
    if (dist > 0.01) {
      avgPace = (state.elapsed.inSeconds / dist).round();
    }

    // ── Territory (simulated: 0.01 km² per 0.5 km run) ──
    final territory = dist * 0.02;

    state = state.copyWith(
      routePoints: points,
      distanceKm: dist,
      avgPaceSecPerKm: avgPace,
      currentPaceSecPerKm: curPace,
      territoryCapturedKm2: territory,
      calories: (dist * 70).round(),
    );
  }

  /// Called every second by the ticker to update elapsed.
  void tick() {
    if (state.status != RunStatus.active || state.startTime == null) return;

    final elapsed = DateTime.now().difference(state.startTime!) - _pauseAccum;
    state = state.copyWith(elapsed: elapsed);
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

class _TimedPoint {
  final LatLng point;
  final DateTime time;
  _TimedPoint(this.point, this.time);
}

// ── Providers ──────────────────────────────────────────────

final runProvider =
    StateNotifierProvider<RunNotifier, RunState>((ref) => RunNotifier());
