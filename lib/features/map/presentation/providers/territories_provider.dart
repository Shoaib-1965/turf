import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turf_app/features/map/data/territory_repository.dart';
import 'package:turf_app/features/map/domain/models/territory.dart';

final territoryRepositoryProvider = Provider<TerritoryRepository>((ref) {
  return TerritoryRepository();
});

class LatLngBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const LatLngBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });
}

class MapBoundsNotifier extends Notifier<LatLngBounds?> {
  @override
  LatLngBounds? build() => null;

  void updateBounds(LatLngBounds bounds) {
    state = bounds;
  }
}

final mapBoundsProvider = NotifierProvider<MapBoundsNotifier, LatLngBounds?>(() {
  return MapBoundsNotifier();
});

final territoriesProvider = StreamProvider<List<Territory>>((ref) {
  final bounds = ref.watch(mapBoundsProvider);
  if (bounds == null) return Stream.value([]);

  final repository = ref.watch(territoryRepositoryProvider);
  return repository.streamTerritoriesInBounds(
    minLat: bounds.south,
    maxLat: bounds.north,
    minLng: bounds.west,
    maxLng: bounds.east,
  );
});
