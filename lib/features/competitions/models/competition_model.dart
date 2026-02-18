/// Data model for the active competition.
class CompetitionModel {
  final String id;
  final String prizeName;
  final String prizeImageUrl;
  final DateTime endDate;
  final int userEntries;
  final int totalEntries;
  final List<PastCompetition> pastCompetitions;

  const CompetitionModel({
    required this.id,
    required this.prizeName,
    required this.prizeImageUrl,
    required this.endDate,
    this.userEntries = 0,
    this.totalEntries = 0,
    this.pastCompetitions = const [],
  });

  /// Approximate win probability.
  double get winProbability =>
      totalEntries > 0 ? (userEntries / totalEntries).clamp(0.0, 1.0) : 0;
}

/// A completed past competition.
class PastCompetition {
  final String id;
  final String prizeName;
  final String prizeImageUrl;
  final String winnerUsername;
  final String winnerPhotoUrl;
  final String monthLabel;
  final int userEntries;

  const PastCompetition({
    required this.id,
    required this.prizeName,
    required this.prizeImageUrl,
    required this.winnerUsername,
    required this.winnerPhotoUrl,
    required this.monthLabel,
    this.userEntries = 0,
  });
}
