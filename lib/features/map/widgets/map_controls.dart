import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

/// Right-side stack of glass circular icon buttons for map control.
class MapControls extends StatelessWidget {
  final VoidCallback onRecenter;
  final VoidCallback onToggleTileStyle;
  final VoidCallback onToggleTerritories;
  final bool isLightTile;
  final bool showTerritories;

  const MapControls({
    super.key,
    required this.onRecenter,
    required this.onToggleTileStyle,
    required this.onToggleTerritories,
    this.isLightTile = true,
    this.showTerritories = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassIconBtn(
          icon: Icons.my_location_rounded,
          tooltip: 'Re-center',
          onTap: onRecenter,
        ),
        const SizedBox(height: 8),
        _GlassIconBtn(
          icon: isLightTile ? Icons.satellite_alt : Icons.map_outlined,
          tooltip: isLightTile ? 'Satellite view' : 'Light view',
          onTap: onToggleTileStyle,
        ),
        const SizedBox(height: 8),
        _GlassIconBtn(
          icon: showTerritories
              ? Icons.visibility_rounded
              : Icons.visibility_off_rounded,
          tooltip: showTerritories ? 'Hide territories' : 'Show territories',
          onTap: onToggleTerritories,
        ),
      ],
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.60),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.80),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryTeal),
            ),
          ),
        ),
      ),
    );
  }
}
