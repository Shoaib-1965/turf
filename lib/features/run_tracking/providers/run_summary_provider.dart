import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'run_provider.dart';

// ── Achievement model ──────────────────────────────────────
class Achievement {
  final String emoji;
  final String name;
  final String subtitle;

  const Achievement({
    required this.emoji,
    required this.name,
    required this.subtitle,
  });
}

// ── Run summary data ──────────────────────────────────────
class RunSummaryData {
  final double distanceKm;
  final String durationFormatted;
  final String avgPace;
  final String bestPace;
  final double territoryCapturedKm2;
  final int calories;
  final List<LatLng> routePoints;
  final DateTime? startTime;
  final List<Achievement> achievements;

  // Territory breakdown
  final double newTerritory;
  final double reclaimedTerritory;
  final int competitionPoints;

  const RunSummaryData({
    this.distanceKm = 0,
    this.durationFormatted = '00:00',
    this.avgPace = '--:--',
    this.bestPace = '--:--',
    this.territoryCapturedKm2 = 0,
    this.calories = 0,
    this.routePoints = const [],
    this.startTime,
    this.achievements = const [],
    this.newTerritory = 0,
    this.reclaimedTerritory = 0,
    this.competitionPoints = 0,
  });
}

// ── Provider ─────────────────────────────────────────────
final runSummaryProvider = Provider<RunSummaryData>((ref) {
  final runState = ref.watch(runProvider);

  // Calculate achievements based on run data
  final achievements = <Achievement>[];

  if (runState.routePoints.isNotEmpty) {
    achievements.add(const Achievement(
      emoji: '🏃',
      name: 'First Run',
      subtitle: 'Complete a run',
    ));
  }

  if (runState.territoryCapturedKm2 > 0) {
    achievements.add(const Achievement(
      emoji: '🗺️',
      name: 'Territory Rookie',
      subtitle: 'Claim territory',
    ));
  }

  if (runState.avgPaceSecPerKm > 0 && runState.avgPaceSecPerKm < 360) {
    achievements.add(const Achievement(
      emoji: '⚡',
      name: 'Speed Demon',
      subtitle: 'Pace under 6:00/km',
    ));
  }

  if (runState.distanceKm >= 5) {
    achievements.add(const Achievement(
      emoji: '🏅',
      name: '5K Runner',
      subtitle: 'Run 5 km+',
    ));
  }

  if (runState.distanceKm >= 10) {
    achievements.add(const Achievement(
      emoji: '🏆',
      name: '10K Runner',
      subtitle: 'Run 10 km+',
    ));
  }

  // Territory breakdown (simulated proportions)
  final total = runState.territoryCapturedKm2;
  final newT = total * 0.7;
  final reclaimed = total * 0.3;
  final points = (total * 100).round();

  // Best pace (simulated: avg - 15%)
  String bestPace = '--:--';
  if (runState.avgPaceSecPerKm > 0) {
    final bestSec = (runState.avgPaceSecPerKm * 0.85).round();
    final m = bestSec ~/ 60;
    final s = bestSec % 60;
    bestPace = '$m:${s.toString().padLeft(2, '0')}';
  }

  return RunSummaryData(
    distanceKm: runState.distanceKm,
    durationFormatted: runState.durationFormatted,
    avgPace: runState.avgPaceFormatted,
    bestPace: bestPace,
    territoryCapturedKm2: total,
    calories: runState.calories,
    routePoints: runState.routePoints,
    startTime: runState.startTime,
    achievements: achievements,
    newTerritory: newT,
    reclaimedTerritory: reclaimed,
    competitionPoints: points,
  );
});
