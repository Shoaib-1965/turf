import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_app/features/leaderboard/domain/models/leaderboard_entry.dart';

class LeaderboardRepository {
  final SupabaseClient _supabase;

  LeaderboardRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  Future<List<LeaderboardEntry>> getGlobalLeaderboard(String type) async {
    final response = await _supabase
        .from('leaderboard_entries')
        .select('*, profiles(id, username, full_name, avatar_url, level, terra_color)')
        .eq('leaderboard_type', type)
        .order('rank', ascending: true)
        .limit(100);

    return (response as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<List<LeaderboardEntry>> getFriendsLeaderboard(String type) async {
    // 1. Get friend IDs
    final friendsResponse = await _supabase
        .from('friendships')
        .select('requester_id, addressee_id')
        .or('requester_id.eq.$_currentUserId,addressee_id.eq.$_currentUserId')
        .eq('status', 'accepted');

    final friendIds = <String>{_currentUserId}; // Include self
    for (var row in friendsResponse) {
      final reqId = row['requester_id'] as String;
      final addId = row['addressee_id'] as String;
      friendIds.add(reqId == _currentUserId ? addId : reqId);
    }

    // 2. Fetch leaderboard entries for these IDs
    final response = await _supabase
        .from('leaderboard_entries')
        .select('*, profiles(id, username, full_name, avatar_url, level, terra_color)')
        .eq('leaderboard_type', type)
        .inFilter('user_id', friendIds.toList())
        .order('value', ascending: false) // Order by value desc since rank is global
        .limit(100);

    return (response as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<LeaderboardEntry?> getCurrentUserEntry(String type) async {
    final response = await _supabase
        .from('leaderboard_entries')
        .select('*, profiles(id, username, full_name, avatar_url, level, terra_color)')
        .eq('leaderboard_type', type)
        .eq('user_id', _currentUserId)
        .maybeSingle();

    if (response == null) return null;
    return LeaderboardEntry.fromJson(response);
  }
}
