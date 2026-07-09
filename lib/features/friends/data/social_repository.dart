import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_app/features/friends/domain/models/friendship.dart';
import 'package:turf_app/features/profile/domain/models/profile.dart';

class SocialRepository {
  final SupabaseClient _supabase;

  SocialRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser!.id;

  // ─── FRIENDS ───────────────────────────────────────────────

  /// Get friends list (accepted friendships)
  Future<List<Friendship>> getFriends() async {
    final response = await _supabase
        .from('friendships')
        .select('*, requester:profiles!friendships_requester_id_fkey(*), addressee:profiles!friendships_addressee_id_fkey(*)')
        .or('requester_id.eq.$_currentUserId,addressee_id.eq.$_currentUserId')
        .eq('status', 'accepted')
        .order('updated_at', ascending: false);

    return (response as List).map((e) => Friendship.fromJson(e)).toList();
  }

  /// Get pending friend requests received by the current user
  Future<List<Friendship>> getPendingRequests() async {
    final response = await _supabase
        .from('friendships')
        .select('*, requester:profiles!friendships_requester_id_fkey(*), addressee:profiles!friendships_addressee_id_fkey(*)')
        .eq('addressee_id', _currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Friendship.fromJson(e)).toList();
  }

  /// Get outgoing friend requests sent by the current user
  Future<List<Friendship>> getOutgoingRequests() async {
    final response = await _supabase
        .from('friendships')
        .select('*, requester:profiles!friendships_requester_id_fkey(*), addressee:profiles!friendships_addressee_id_fkey(*)')
        .eq('requester_id', _currentUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Friendship.fromJson(e)).toList();
  }

  // ─── SEARCH ────────────────────────────────────────────────

  /// Search users by username OR full_name
  Future<List<Profile>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _supabase
        .from('profiles')
        .select()
        .or('username.ilike.%$query%,full_name.ilike.%$query%')
        .neq('id', _currentUserId)
        .limit(20);

    return (response as List).map((e) => Profile.fromJson(e)).toList();
  }

  /// Get a single profile by ID
  Future<Profile> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(response);
  }

  // ─── FRIEND ACTIONS ────────────────────────────────────────

  /// Send a friend request. Checks for duplicates first.
  /// Returns a status string: 'sent', 'already_friends', 'already_pending', 'error'
  Future<String> sendFriendRequest(String toUserId) async {
    if (toUserId == _currentUserId) return 'error';

    // Check for existing relationship in either direction
    final existing = await _supabase
        .from('friendships')
        .select('id, status')
        .or('and(requester_id.eq.$_currentUserId,addressee_id.eq.$toUserId),and(requester_id.eq.$toUserId,addressee_id.eq.$_currentUserId)')
        .maybeSingle();

    if (existing != null) {
      final status = existing['status'] as String;
      if (status == 'accepted') return 'already_friends';
      if (status == 'pending') return 'already_pending';
    }

    await _supabase.from('friendships').insert({
      'requester_id': _currentUserId,
      'addressee_id': toUserId,
      'status': 'pending',
    });

    return 'sent';
  }

  /// Accept or decline a friend request
  Future<void> respondToRequest(String friendshipId, bool accept) async {
    if (accept) {
      await _supabase
          .from('friendships')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', friendshipId);
    } else {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId);
    }
  }

  /// Unfriend a user (delete the friendship row)
  Future<void> deleteFriendship(String userId) async {
    await _supabase
        .from('friendships')
        .delete()
        .or('and(requester_id.eq.$_currentUserId,addressee_id.eq.$userId),and(requester_id.eq.$userId,addressee_id.eq.$_currentUserId)');
  }

  // ─── DISCOVER ──────────────────────────────────────────────

  /// Get users to discover (not already friends or pending)
  Future<List<Profile>> getDiscoverUsers() async {
    // 1. Get current user profile for XP proximity sorting
    final myProfile = await getProfile(_currentUserId);
    final myXp = myProfile.totalXp;

    // 2. Get all user IDs with any friendship status
    final friendships = await _supabase
        .from('friendships')
        .select('requester_id, addressee_id')
        .or('requester_id.eq.$_currentUserId,addressee_id.eq.$_currentUserId');
    
    final excludeIds = <String>{_currentUserId};
    for (var f in friendships as List) {
      excludeIds.add(f['requester_id'] == _currentUserId ? f['addressee_id'] : f['requester_id']);
    }

    // 3. Fetch users NOT in exclude set
    final response = await _supabase
        .from('profiles')
        .select()
        .not('id', 'in', '(${excludeIds.join(",")})')
        .limit(50);
        
    final profiles = (response as List).map((e) => Profile.fromJson(e)).toList();
    
    // Sort by proximity to current user's XP
    profiles.sort((a, b) => (a.totalXp - myXp).abs().compareTo((b.totalXp - myXp).abs()));
    
    return profiles;
  }

  // ─── STATUS CHECK ──────────────────────────────────────────

  /// Check the friendship status between the current user and another user.
  /// Returns: 'you', 'none', 'pending_sent', 'pending_received', 'accepted'
  Future<String> checkFriendshipStatus(String userId) async {
    if (userId == _currentUserId) return 'you';
    
    final response = await _supabase
        .from('friendships')
        .select('id, status, requester_id')
        .or('and(requester_id.eq.$_currentUserId,addressee_id.eq.$userId),and(requester_id.eq.$userId,addressee_id.eq.$_currentUserId)')
        .maybeSingle();
        
    if (response == null) return 'none';
    
    final status = response['status'] as String;
    if (status == 'accepted') return 'accepted';
    
    // Distinguish who sent the pending request
    final requesterId = response['requester_id'] as String;
    if (requesterId == _currentUserId) return 'pending_sent';
    return 'pending_received';
  }

  /// Batch-check friendship statuses for a list of user IDs.
  /// Returns a map of userId → status string.
  Future<Map<String, String>> batchCheckFriendshipStatus(List<String> userIds) async {
    final result = <String, String>{};
    for (var id in userIds) {
      if (id == _currentUserId) {
        result[id] = 'you';
      } else {
        result[id] = 'none';
      }
    }

    if (userIds.isEmpty) return result;

    final friendships = await _supabase
        .from('friendships')
        .select('requester_id, addressee_id, status')
        .or('requester_id.eq.$_currentUserId,addressee_id.eq.$_currentUserId');

    for (var f in friendships as List) {
      final reqId = f['requester_id'] as String;
      final addId = f['addressee_id'] as String;
      final status = f['status'] as String;
      final otherId = reqId == _currentUserId ? addId : reqId;

      if (result.containsKey(otherId)) {
        if (status == 'accepted') {
          result[otherId] = 'accepted';
        } else if (status == 'pending') {
          result[otherId] = reqId == _currentUserId ? 'pending_sent' : 'pending_received';
        }
      }
    }

    return result;
  }
}
