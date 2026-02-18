import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_entry.dart';

// ── Enums ──────────────────────────────────────────────────
enum LeaderboardTab { global, local, friends }

enum LeaderboardPeriod { thisMonth, thisWeek, allTime }

// ── Provider key ───────────────────────────────────────────
typedef LeaderboardKey = ({LeaderboardTab tab, LeaderboardPeriod period});

// ── Mock names & avatars ──────────────────────────────────
const _mockNames = [
  'Alex Rivera',
  'Jordan Lee',
  'Sam Cooper',
  'Taylor Kim',
  'Morgan Chen',
  'Casey Brooks',
  'Jamie Patel',
  'Riley Nakamura',
  'Dakota Osei',
  'Quinn Murphy',
  'Avery Santos',
  'Skyler Tanaka',
  'Drew Fischer',
  'Reese Andrade',
  'Emery Johansson',
  'Finley Okoro',
  'Harper Wei',
  'Rowan Malik',
  'Blake Larson',
  'Charlie Duarte',
];

// ── Provider ──────────────────────────────────────────────
final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, LeaderboardKey>(
  (ref, key) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final rng = Random(key.tab.index * 10 + key.period.index);

    // Generate 20 mock entries sorted by territory descending
    final territories = List.generate(20, (_) => rng.nextDouble() * 12 + 0.5)
      ..sort((a, b) => b.compareTo(a));

    return List.generate(20, (i) {
      final isCurrentUser = i == 6; // Place current user at rank 7
      return LeaderboardEntry(
        rank: i + 1,
        userId: isCurrentUser ? 'current_user' : 'user_${key.tab.name}_$i',
        username: isCurrentUser ? 'You' : _mockNames[i % _mockNames.length],
        photoUrl:
            'https://i.pravatar.cc/150?img=${(i + key.tab.index * 5) % 70}',
        territoryKm2: double.parse(territories[i].toStringAsFixed(2)),
        rankChange: (rng.nextInt(7) - 3), // -3 to +3
        runsThisWeek: rng.nextInt(12) + 1,
      );
    });
  },
);
