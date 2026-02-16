import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/models/territory_model.dart';

/// Provides mock territory data near a test coordinate.
/// In production this would fetch from Firestore.
final territoriesProvider = FutureProvider<List<TerritoryModel>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 400));

  // Test center: Islamabad, Pakistan (roughly)
  const baseLat = 33.6844;
  const baseLng = 73.0479;
  const d = 0.002; // ≈ 200 m offset

  return [
    // ── Own territories (teal) ────────────────────────────
    TerritoryModel(
      id: 't1',
      ownerId: 'me',
      ownerName: 'You',
      coordinates: [
        LatLng(baseLat, baseLng),
        LatLng(baseLat + d, baseLng),
        LatLng(baseLat + d, baseLng + d),
        LatLng(baseLat, baseLng + d),
      ],
      areaKm2: 0.04,
      type: TerritoryType.own,
      capturedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TerritoryModel(
      id: 't2',
      ownerId: 'me',
      ownerName: 'You',
      coordinates: [
        LatLng(baseLat + d, baseLng),
        LatLng(baseLat + 2 * d, baseLng),
        LatLng(baseLat + 2 * d, baseLng + d),
        LatLng(baseLat + d, baseLng + d),
      ],
      areaKm2: 0.04,
      type: TerritoryType.own,
      capturedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),

    // ── Enemy territories (red) ──────────────────────────
    TerritoryModel(
      id: 't3',
      ownerId: 'enemy1',
      ownerName: 'ShadowRunner',
      ownerPhotoUrl: null,
      coordinates: [
        LatLng(baseLat - d, baseLng),
        LatLng(baseLat, baseLng),
        LatLng(baseLat, baseLng - d),
        LatLng(baseLat - d, baseLng - d),
      ],
      areaKm2: 0.04,
      type: TerritoryType.enemy,
      capturedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    TerritoryModel(
      id: 't4',
      ownerId: 'enemy2',
      ownerName: 'StreetKing',
      ownerPhotoUrl: null,
      coordinates: [
        LatLng(baseLat - d, baseLng + d),
        LatLng(baseLat, baseLng + d),
        LatLng(baseLat, baseLng + 2 * d),
        LatLng(baseLat - d, baseLng + 2 * d),
      ],
      areaKm2: 0.04,
      type: TerritoryType.enemy,
      capturedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),

    // ── Friend territory (blue) ──────────────────────────
    TerritoryModel(
      id: 't5',
      ownerId: 'friend1',
      ownerName: 'PacePilot',
      ownerPhotoUrl: null,
      coordinates: [
        LatLng(baseLat + d, baseLng - d),
        LatLng(baseLat + 2 * d, baseLng - d),
        LatLng(baseLat + 2 * d, baseLng),
        LatLng(baseLat + d, baseLng),
      ],
      areaKm2: 0.04,
      type: TerritoryType.friend,
      capturedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // ── Unclaimed ─────────────────────────────────────────
    TerritoryModel(
      id: 't6',
      ownerId: '',
      ownerName: 'Unclaimed',
      coordinates: [
        LatLng(baseLat - d, baseLng - 2 * d),
        LatLng(baseLat, baseLng - 2 * d),
        LatLng(baseLat, baseLng - d),
        LatLng(baseLat - d, baseLng - d),
      ],
      areaKm2: 0.04,
      type: TerritoryType.unclaimed,
      capturedAt: DateTime.now(),
    ),
  ];
});

/// Total own territory area in km².
final ownTerritoryAreaProvider = FutureProvider<double>((ref) async {
  final territories = await ref.watch(territoriesProvider.future);
  return territories
      .where((t) => t.type == TerritoryType.own)
      .fold<double>(0, (sum, t) => sum + t.areaKm2);
});
