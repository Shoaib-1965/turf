import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turf_app/features/map/domain/models/claimed_territory.dart';

final territoryClaimRepositoryProvider = Provider((ref) => TerritoryClaimRepository());

class TerritoryClaimRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Insert a new claimed territory into the database.
  /// Returns the inserted row's id.
  Future<String> insertClaim({
    required String sessionId,
    required List<Position> polygon,
    String colorHex = '#00E676',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // Build GeoJSON polygon
    final ring = polygon.map((p) => [p.lng.toDouble(), p.lat.toDouble()]).toList();
    // Ensure ring is closed
    if (ring.isNotEmpty && (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add(List<double>.from(ring.first));
    }
    final geoJson = jsonEncode({
      'type': 'Polygon',
      'coordinates': [ring],
    });

    final result = await _supabase
        .from('claimed_territories')
        .insert({
          'owner_id': userId,
          'session_id': sessionId,
          'geom': geoJson,
          'color_hex': colorHex,
        })
        .select('id, area_sqm')
        .single();

    final insertedId = result['id'] as String;
    final areaSqm = (result['area_sqm'] as num).toDouble();

    // Award XP via server function
    await _supabase.rpc('award_territory_claim', params: {
      'p_user_id': userId,
      'p_area_sqm': areaSqm,
    });

    return insertedId;
  }

  /// Fetch all claimed territories (with owner profile joined).
  /// Optionally filter to a viewport bounding box.
  Future<List<ClaimedTerritory>> fetchClaimedTerritories() async {
    final data = await _supabase
        .from('claimed_territories')
        .select('*, profiles!claimed_territories_owner_id_fkey(full_name, avatar_url, level, total_xp, terra_color)')
        .eq('is_active', true)
        .order('claimed_at', ascending: false)
        .limit(200);

    return (data as List).map((e) => ClaimedTerritory.fromJson(e)).toList();
  }

  /// Fetch claimed territories owned by a specific user.
  Future<List<ClaimedTerritory>> fetchUserClaimedTerritories(String userId) async {
    final data = await _supabase
        .from('claimed_territories')
        .select('*, profiles!claimed_territories_owner_id_fkey(full_name, avatar_url, level, total_xp, terra_color)')
        .eq('owner_id', userId)
        .eq('is_active', true)
        .order('claimed_at', ascending: false);

    return (data as List).map((e) => ClaimedTerritory.fromJson(e)).toList();
  }

  /// Subscribe to real-time changes on claimed_territories.
  /// Calls [onInsert] when any user claims a new territory.
  RealtimeChannel subscribeToClaimedTerritories({
    required void Function(ClaimedTerritory) onInsert,
  }) {
    return _supabase
        .channel('claimed_territories_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'claimed_territories',
          callback: (payload) async {
            try {
              // Fetch the full record with profile join
              final data = await _supabase
                  .from('claimed_territories')
                  .select('*, profiles!claimed_territories_owner_id_fkey(full_name, avatar_url, level, total_xp, terra_color)')
                  .eq('id', payload.newRecord['id'])
                  .single();
              onInsert(ClaimedTerritory.fromJson(data));
            } catch (_) {}
          },
        )
        .subscribe();
  }
}
