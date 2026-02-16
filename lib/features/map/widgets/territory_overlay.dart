import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/territory_model.dart';

/// Converts a list of [TerritoryModel] into a [PolygonLayer] for FlutterMap.
class TerritoryOverlay extends StatelessWidget {
  final List<TerritoryModel> territories;
  final void Function(TerritoryModel territory)? onTerritoryTap;

  const TerritoryOverlay({
    super.key,
    required this.territories,
    this.onTerritoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return PolygonLayer(
      polygons: territories.map(_toPolygon).toList(),
    );
  }

  Polygon _toPolygon(TerritoryModel t) {
    final (fill, border) = _colors(t.type);

    return Polygon(
      points: t.coordinates,
      color: fill,
      borderColor: border,
      borderStrokeWidth: 2.0,
      label: t.type == TerritoryType.unclaimed ? '?' : null,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static (Color fill, Color border) _colors(TerritoryType type) {
    switch (type) {
      case TerritoryType.own:
        return (
          AppColors.ownTerritory.withValues(alpha: 0.30),
          AppColors.ownTerritory,
        );
      case TerritoryType.friend:
        return (
          AppColors.friendTerritory.withValues(alpha: 0.30),
          AppColors.friendTerritory,
        );
      case TerritoryType.enemy:
        return (
          AppColors.enemyTerritory.withValues(alpha: 0.30),
          AppColors.enemyTerritory,
        );
      case TerritoryType.unclaimed:
        return (
          Colors.grey.withValues(alpha: 0.15),
          Colors.grey.withValues(alpha: 0.40),
        );
    }
  }
}
