import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/social_post.dart';

// ── Social feed provider ─────────────────────────────────
final socialFeedProvider = FutureProvider<List<SocialPost>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));

  final now = DateTime.now();
  return [
    SocialPost(
      id: 'p1',
      userId: 'u1',
      username: 'PacePilot',
      photoUrl: 'https://i.pravatar.cc/100?img=10',
      type: SocialPostType.run,
      createdAt: now.subtract(const Duration(minutes: 12)),
      likes: 24,
      comments: 3,
      isLiked: true,
      distanceKm: 5.2,
      duration: '26:14',
      pace: '5:03',
      territoryKm2: 0.34,
      caption: 'Morning loop through the park 🌅',
    ),
    SocialPost(
      id: 'p2',
      userId: 'u2',
      username: 'StreetKing',
      photoUrl: 'https://i.pravatar.cc/100?img=15',
      type: SocialPostType.territoryMilestone,
      createdAt: now.subtract(const Duration(hours: 2)),
      likes: 41,
      comments: 8,
      totalTerritory: 5.0,
      caption: 'Hit 5 km² total territory!',
    ),
    SocialPost(
      id: 'p3',
      userId: 'u3',
      username: 'TurfMaster',
      photoUrl: 'https://i.pravatar.cc/100?img=22',
      type: SocialPostType.achievement,
      createdAt: now.subtract(const Duration(hours: 4)),
      likes: 18,
      comments: 2,
      badgeEmoji: '⚡',
      badgeName: 'Speed Demon',
      badgeDescription: 'Ran a sub-5:00/km pace for 5 km',
    ),
    SocialPost(
      id: 'p4',
      userId: 'u4',
      username: 'SprintQueen',
      photoUrl: 'https://i.pravatar.cc/100?img=32',
      type: SocialPostType.run,
      createdAt: now.subtract(const Duration(hours: 6)),
      likes: 12,
      comments: 1,
      isFollowing: false,
      distanceKm: 3.1,
      duration: '18:45',
      pace: '6:03',
      territoryKm2: 0.18,
    ),
    SocialPost(
      id: 'p5',
      userId: 'u5',
      username: 'TrailBlazer',
      photoUrl: 'https://i.pravatar.cc/100?img=45',
      type: SocialPostType.run,
      createdAt: now.subtract(const Duration(hours: 8)),
      likes: 31,
      comments: 5,
      isLiked: true,
      distanceKm: 10.5,
      duration: '58:22',
      pace: '5:33',
      territoryKm2: 0.76,
      caption: 'Long run Sunday 💪 New PB distance!',
    ),
    SocialPost(
      id: 'p6',
      userId: 'u6',
      username: 'NightRunner',
      photoUrl: 'https://i.pravatar.cc/100?img=51',
      type: SocialPostType.territoryMilestone,
      createdAt: now.subtract(const Duration(hours: 12)),
      likes: 28,
      comments: 4,
      totalTerritory: 3.0,
      caption: '3 km² and counting!',
    ),
    SocialPost(
      id: 'p7',
      userId: 'u7',
      username: 'MileMuncher',
      photoUrl: 'https://i.pravatar.cc/100?img=55',
      type: SocialPostType.achievement,
      createdAt: now.subtract(const Duration(days: 1)),
      likes: 9,
      comments: 1,
      isFollowing: false,
      badgeEmoji: '🔥',
      badgeName: '7-Day Streak',
      badgeDescription: 'Ran every day for 7 days in a row',
    ),
    SocialPost(
      id: 'p8',
      userId: 'u8',
      username: 'UrbanExplorer',
      photoUrl: 'https://i.pravatar.cc/100?img=60',
      type: SocialPostType.run,
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      likes: 15,
      comments: 2,
      distanceKm: 7.8,
      duration: '42:10',
      pace: '5:24',
      territoryKm2: 0.52,
      caption: 'Explored the old town district!',
    ),
    SocialPost(
      id: 'p9',
      userId: 'u9',
      username: 'DawnPatrol',
      photoUrl: 'https://i.pravatar.cc/100?img=63',
      type: SocialPostType.run,
      createdAt: now.subtract(const Duration(days: 2)),
      likes: 7,
      comments: 0,
      distanceKm: 4.0,
      duration: '24:00',
      pace: '6:00',
      territoryKm2: 0.22,
    ),
    SocialPost(
      id: 'p10',
      userId: 'u10',
      username: 'ZoneRunner',
      photoUrl: 'https://i.pravatar.cc/100?img=67',
      type: SocialPostType.achievement,
      createdAt: now.subtract(const Duration(days: 2, hours: 5)),
      likes: 22,
      comments: 3,
      badgeEmoji: '👑',
      badgeName: 'Top 10',
      badgeDescription: 'Reached the top 10 on the global leaderboard',
    ),
  ];
});

// ── Live friends provider ────────────────────────────────
final liveFriendsProvider = FutureProvider<List<LiveFriend>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return const [
    LiveFriend(
      userId: 'u1',
      username: 'PacePilot',
      photoUrl: 'https://i.pravatar.cc/100?img=10',
      currentDistanceKm: 2.4,
    ),
    LiveFriend(
      userId: 'u5',
      username: 'TrailBlazer',
      photoUrl: 'https://i.pravatar.cc/100?img=45',
      currentDistanceKm: 5.1,
    ),
    LiveFriend(
      userId: 'u8',
      username: 'UrbanExplorer',
      photoUrl: 'https://i.pravatar.cc/100?img=60',
      currentDistanceKm: 1.8,
    ),
  ];
});

// ── Discover suggestions provider ────────────────────────
final discoverUsersProvider = FutureProvider<List<SuggestedUser>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 400));
  return const [
    SuggestedUser(
        userId: 's1',
        username: 'MapHunter',
        photoUrl: 'https://i.pravatar.cc/100?img=5',
        territoryKm2: 3.2,
        mutualFriends: 4),
    SuggestedUser(
        userId: 's2',
        username: 'TurfWarrior',
        photoUrl: 'https://i.pravatar.cc/100?img=8',
        territoryKm2: 2.8,
        mutualFriends: 2),
    SuggestedUser(
        userId: 's3',
        username: 'NightOwlRun',
        photoUrl: 'https://i.pravatar.cc/100?img=18',
        territoryKm2: 4.1,
        mutualFriends: 6),
    SuggestedUser(
        userId: 's4',
        username: 'GridRacer',
        photoUrl: 'https://i.pravatar.cc/100?img=25',
        territoryKm2: 1.9,
        mutualFriends: 1),
    SuggestedUser(
        userId: 's5',
        username: 'SunnySprint',
        photoUrl: 'https://i.pravatar.cc/100?img=30',
        territoryKm2: 5.5,
        mutualFriends: 3),
    SuggestedUser(
        userId: 's6',
        username: 'PeakChaser',
        photoUrl: 'https://i.pravatar.cc/100?img=38',
        territoryKm2: 2.3,
        mutualFriends: 0),
  ];
});
