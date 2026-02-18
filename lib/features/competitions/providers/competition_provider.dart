import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/competition_model.dart';

// ── Active competition provider ────────────────────────────
final competitionProvider = FutureProvider<CompetitionModel>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));

  // End of current month
  final now = DateTime.now();
  final endOfMonth =
      DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));

  return CompetitionModel(
    id: 'comp_feb_2026',
    prizeName: 'GARMIN FORERUNNER 965',
    prizeImageUrl: 'https://i.imgur.com/YZjqGJc.png',
    endDate: endOfMonth,
    userEntries: 24,
    totalEntries: 748,
    pastCompetitions: [
      PastCompetition(
        id: 'comp_jan_2026',
        prizeName: 'Apple Watch Ultra 2',
        prizeImageUrl: 'https://i.pravatar.cc/100?img=1',
        winnerUsername: 'StreetKing',
        winnerPhotoUrl: 'https://i.pravatar.cc/50?img=15',
        monthLabel: 'January 2026',
        userEntries: 18,
      ),
      PastCompetition(
        id: 'comp_dec_2025',
        prizeName: 'Nike Vaporfly 3',
        prizeImageUrl: 'https://i.pravatar.cc/100?img=2',
        winnerUsername: 'PacePilot',
        winnerPhotoUrl: 'https://i.pravatar.cc/50?img=22',
        monthLabel: 'December 2025',
        userEntries: 12,
      ),
      PastCompetition(
        id: 'comp_nov_2025',
        prizeName: 'AirPods Pro 3',
        prizeImageUrl: 'https://i.pravatar.cc/100?img=3',
        winnerUsername: 'TurfMaster',
        winnerPhotoUrl: 'https://i.pravatar.cc/50?img=33',
        monthLabel: 'November 2025',
        userEntries: 9,
      ),
    ],
  );
});

// ── Live countdown stream ──────────────────────────────────
final countdownProvider = StreamProvider<Duration>((ref) async* {
  while (true) {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 1)
        .subtract(const Duration(seconds: 1));
    final remaining = endOfMonth.difference(now);
    yield remaining.isNegative ? Duration.zero : remaining;
    await Future.delayed(const Duration(seconds: 1));
  }
});
