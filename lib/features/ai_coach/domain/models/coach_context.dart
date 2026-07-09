class CoachContext {
  final String? username;
  final int level;
  final int totalXp;
  final double totalDistanceKm;
  final int streakDays;
  final String? currentActivityType;
  final double? currentSpeedKmh;
  final double? currentPaceMinPerKm;
  final double? currentDistanceKm;
  final int? currentDurationSeconds;
  final int? currentCaloriesBurned;
  final double? currentElevationGainM;
  final double? landClaimedSqm;
  final int? leaderboardRank;
  final String? leaderboardType;
  final List<String> activeGoals;
  final List<String> recentBadges;
  final List<String> activeChallenges;

  const CoachContext({
    this.username,
    this.level = 1,
    this.totalXp = 0,
    this.totalDistanceKm = 0.0,
    this.streakDays = 0,
    this.currentActivityType,
    this.currentSpeedKmh,
    this.currentPaceMinPerKm,
    this.currentDistanceKm,
    this.currentDurationSeconds,
    this.currentCaloriesBurned,
    this.currentElevationGainM,
    this.landClaimedSqm,
    this.leaderboardRank,
    this.leaderboardType,
    this.activeGoals = const [],
    this.recentBadges = const [],
    this.activeChallenges = const [],
  });

  /// Whether the user is currently in a live activity session.
  bool get isInLiveActivity => currentActivityType != null;

  /// Formats all non-null data into a readable string for the AI prompt.
  String toContextString() {
    final buffer = StringBuffer();

    buffer.writeln('=== User Profile ===');
    if (username != null) buffer.writeln('Username: $username');
    buffer.writeln('Level: $level');
    buffer.writeln('Total XP: $totalXp');
    buffer.writeln('Total Distance: ${totalDistanceKm.toStringAsFixed(1)} km');
    buffer.writeln('Current Streak: $streakDays days');

    if (isInLiveActivity) {
      buffer.writeln();
      buffer.writeln('=== Live Activity ===');
      buffer.writeln('Activity Type: $currentActivityType');
      if (currentSpeedKmh != null) {
        buffer.writeln(
            'Current Speed: ${currentSpeedKmh!.toStringAsFixed(1)} km/h');
      }
      if (currentPaceMinPerKm != null) {
        buffer.writeln(
            'Current Pace: ${currentPaceMinPerKm!.toStringAsFixed(2)} min/km');
      }
      if (currentDistanceKm != null) {
        buffer.writeln(
            'Distance Covered: ${currentDistanceKm!.toStringAsFixed(2)} km');
      }
      if (currentDurationSeconds != null) {
        final minutes = currentDurationSeconds! ~/ 60;
        final seconds = currentDurationSeconds! % 60;
        buffer.writeln('Duration: ${minutes}m ${seconds}s');
      }
      if (currentCaloriesBurned != null) {
        buffer.writeln('Calories Burned: $currentCaloriesBurned');
      }
      if (currentElevationGainM != null) {
        buffer.writeln(
            'Elevation Gain: ${currentElevationGainM!.toStringAsFixed(1)} m');
      }
    }

    if (landClaimedSqm != null) {
      buffer.writeln();
      buffer.writeln('=== Territory ===');
      buffer.writeln(
          'Land Claimed: ${landClaimedSqm!.toStringAsFixed(0)} sqm');
    }

    if (leaderboardRank != null) {
      buffer.writeln();
      buffer.writeln('=== Leaderboard ===');
      buffer.writeln('Rank: #$leaderboardRank');
      if (leaderboardType != null) {
        buffer.writeln('Leaderboard Type: $leaderboardType');
      }
    }

    if (activeGoals.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== Active Goals ===');
      for (final goal in activeGoals) {
        buffer.writeln('• $goal');
      }
    }

    if (recentBadges.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== Recent Badges ===');
      for (final badge in recentBadges) {
        buffer.writeln('🏅 $badge');
      }
    }

    if (activeChallenges.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('=== Active Challenges ===');
      for (final challenge in activeChallenges) {
        buffer.writeln('🎯 $challenge');
      }
    }

    return buffer.toString();
  }

  CoachContext copyWith({
    String? username,
    int? level,
    int? totalXp,
    double? totalDistanceKm,
    int? streakDays,
    String? currentActivityType,
    double? currentSpeedKmh,
    double? currentPaceMinPerKm,
    double? currentDistanceKm,
    int? currentDurationSeconds,
    int? currentCaloriesBurned,
    double? currentElevationGainM,
    double? landClaimedSqm,
    int? leaderboardRank,
    String? leaderboardType,
    List<String>? activeGoals,
    List<String>? recentBadges,
    List<String>? activeChallenges,
  }) {
    return CoachContext(
      username: username ?? this.username,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      streakDays: streakDays ?? this.streakDays,
      currentActivityType: currentActivityType ?? this.currentActivityType,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentPaceMinPerKm: currentPaceMinPerKm ?? this.currentPaceMinPerKm,
      currentDistanceKm: currentDistanceKm ?? this.currentDistanceKm,
      currentDurationSeconds:
          currentDurationSeconds ?? this.currentDurationSeconds,
      currentCaloriesBurned:
          currentCaloriesBurned ?? this.currentCaloriesBurned,
      currentElevationGainM:
          currentElevationGainM ?? this.currentElevationGainM,
      landClaimedSqm: landClaimedSqm ?? this.landClaimedSqm,
      leaderboardRank: leaderboardRank ?? this.leaderboardRank,
      leaderboardType: leaderboardType ?? this.leaderboardType,
      activeGoals: activeGoals ?? this.activeGoals,
      recentBadges: recentBadges ?? this.recentBadges,
      activeChallenges: activeChallenges ?? this.activeChallenges,
    );
  }
}
