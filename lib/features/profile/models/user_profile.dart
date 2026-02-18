/// Data model for a user's profile.
class UserProfile {
  final String userId;
  final String username;
  final String displayName;
  final String photoUrl;
  final String bio;
  final double totalTerritoryKm2;
  final double totalDistanceKm;
  final double bestPaceSecPerKm;
  final int totalRuns;
  final int globalRank;
  final List<String> achievementIds;
  final List<RunHistoryItem> recentRuns;

  const UserProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.bio,
    this.totalTerritoryKm2 = 0,
    this.totalDistanceKm = 0,
    this.bestPaceSecPerKm = 0,
    this.totalRuns = 0,
    this.globalRank = 0,
    this.achievementIds = const [],
    this.recentRuns = const [],
  });

  bool get isOwnProfile => userId == 'current_user';

  /// Rank percentile (0.0–1.0, higher = better).
  double get rankPercentile =>
      globalRank > 0 ? (1.0 - (globalRank / 250)).clamp(0.0, 1.0) : 0;

  /// Best pace formatted as m:ss.
  String get bestPaceFormatted {
    if (bestPaceSecPerKm <= 0) return '--:--';
    final m = bestPaceSecPerKm ~/ 60;
    final s = (bestPaceSecPerKm % 60).round();
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Summary of one past run for the profile's recent history.
class RunHistoryItem {
  final String runId;
  final DateTime date;
  final double distanceKm;
  final String pace; // formatted "m:ss"
  final double territoryKm2;

  const RunHistoryItem({
    required this.runId,
    required this.date,
    required this.distanceKm,
    required this.pace,
    required this.territoryKm2,
  });
}
