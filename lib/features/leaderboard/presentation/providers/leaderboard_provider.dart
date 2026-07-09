import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turf_app/features/leaderboard/data/leaderboard_repository.dart';
import 'package:turf_app/features/leaderboard/domain/models/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider(
  (ref) => LeaderboardRepository(),
);

class LeaderboardTypeNotifier extends Notifier<String> {
  @override
  String build() => 'weekly_distance';
}

final leaderboardTypeProvider =
    NotifierProvider<LeaderboardTypeNotifier, String>(
      LeaderboardTypeNotifier.new,
    );

class LeaderboardScopeNotifier extends Notifier<String> {
  @override
  String build() => 'global'; // 'global' or 'friends'
}

final leaderboardScopeProvider =
    NotifierProvider<LeaderboardScopeNotifier, String>(
      LeaderboardScopeNotifier.new,
    );

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final type = ref.watch(leaderboardTypeProvider);
  final scope = ref.watch(leaderboardScopeProvider);

  if (scope == 'global') {
    return repo.getGlobalLeaderboard(type);
  } else {
    return repo.getFriendsLeaderboard(type);
  }
});

final currentUserLeaderboardEntryProvider = FutureProvider<LeaderboardEntry?>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final type = ref.watch(leaderboardTypeProvider);
  return repo.getCurrentUserEntry(type);
});
