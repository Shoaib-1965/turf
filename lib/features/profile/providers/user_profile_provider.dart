import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';

// ── Mock achievements ──────────────────────────────────────
class AchievementDef {
  final String id;
  final String emoji;
  final String name;

  const AchievementDef(this.id, this.emoji, this.name);
}

const allAchievements = [
  AchievementDef('first_run', '🏃', 'First Run'),
  AchievementDef('territory', '🗺️', 'Territory Rookie'),
  AchievementDef('crown', '👑', 'Top 10'),
  AchievementDef('speed', '⚡', 'Speed Demon'),
  AchievementDef('streak', '🔥', '7-Day Streak'),
  AchievementDef('power', '💪', '50 km Total'),
  AchievementDef('globe', '🌍', '10 km² Owned'),
  AchievementDef('battle', '⚔️', 'Territory War'),
];

// ── Provider ──────────────────────────────────────────────
final userProfileProvider =
    FutureProvider.family<UserProfile, String>((ref, userId) async {
  await Future.delayed(const Duration(milliseconds: 500));

  final isOwn = userId.isEmpty || userId == 'current_user';

  return UserProfile(
    userId: isOwn ? 'current_user' : userId,
    username: isOwn ? 'TurfRunner42' : 'User_$userId',
    displayName: isOwn ? 'Alex Rivera' : 'User $userId',
    photoUrl:
        'https://i.pravatar.cc/200?img=${isOwn ? 12 : userId.hashCode % 70}',
    bio: isOwn
        ? 'Running the streets. Claiming the turf. 🏃‍♂️🗺️'
        : 'Fellow runner on the turf.',
    totalTerritoryKm2: isOwn ? 2.41 : 1.87,
    totalDistanceKm: isOwn ? 142.6 : 98.3,
    bestPaceSecPerKm: isOwn ? 295 : 320, // ~4:55 and ~5:20
    totalRuns: isOwn ? 38 : 24,
    globalRank: isOwn ? 12 : 45,
    achievementIds: isOwn
        ? ['first_run', 'territory', 'crown', 'speed', 'streak']
        : ['first_run', 'territory'],
    recentRuns: [
      RunHistoryItem(
        runId: 'r1',
        date: DateTime.now().subtract(const Duration(days: 1)),
        distanceKm: 5.2,
        pace: '5:12',
        territoryKm2: 0.32,
      ),
      RunHistoryItem(
        runId: 'r2',
        date: DateTime.now().subtract(const Duration(days: 3)),
        distanceKm: 3.8,
        pace: '5:45',
        territoryKm2: 0.18,
      ),
      RunHistoryItem(
        runId: 'r3',
        date: DateTime.now().subtract(const Duration(days: 5)),
        distanceKm: 7.1,
        pace: '4:55',
        territoryKm2: 0.56,
      ),
      RunHistoryItem(
        runId: 'r4',
        date: DateTime.now().subtract(const Duration(days: 7)),
        distanceKm: 4.5,
        pace: '5:30',
        territoryKm2: 0.22,
      ),
      RunHistoryItem(
        runId: 'r5',
        date: DateTime.now().subtract(const Duration(days: 10)),
        distanceKm: 6.3,
        pace: '5:08',
        territoryKm2: 0.41,
      ),
    ],
  );
});
