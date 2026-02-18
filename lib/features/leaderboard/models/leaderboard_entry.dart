/// Data model for a single leaderboard row.
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String photoUrl;
  final double territoryKm2;
  final int rankChange; // positive = up, negative = down, 0 = no change
  final int runsThisWeek;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.photoUrl,
    required this.territoryKm2,
    this.rankChange = 0,
    this.runsThisWeek = 0,
  });

  bool get isCurrentUser => userId == 'current_user';
}
