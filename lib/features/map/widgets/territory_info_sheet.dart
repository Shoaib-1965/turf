import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/territory_model.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_modal.dart';

/// Bottom sheet shown when user taps a territory polygon.
class TerritoryInfoSheet {
  TerritoryInfoSheet._();

  static Future<void> show(BuildContext context, TerritoryModel t) {
    return GlassModal.show(
      context: context,
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.5,
      child: _Content(territory: t),
    );
  }
}

class _Content extends StatelessWidget {
  final TerritoryModel territory;

  const _Content({required this.territory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Owner row ─────────────────────────────────────
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _typeColor.withValues(alpha: 0.15),
              child: Text(
                territory.ownerName.isNotEmpty
                    ? territory.ownerName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _typeColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    territory.ownerName,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Captured ${territory.daysSinceCaptured} days ago',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Territory size ────────────────────────────────
        Text(
          '${territory.areaKm2.toStringAsFixed(2)} km²',
          style: GoogleFonts.robotoMono(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTeal,
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // ── Action / chip ─────────────────────────────────
        _buildAction(context),
      ],
    );
  }

  Widget _buildAction(BuildContext context) {
    switch (territory.type) {
      case TerritoryType.own:
        return _chip('🏆 Your Territory', AppColors.primaryTeal);
      case TerritoryType.friend:
        return _chip("👥 Friend's Territory", AppColors.friendTerritory);
      case TerritoryType.enemy:
        return GlassButton(
          text: '⚔️ Battle for this territory',
          style: GlassButtonStyle.danger,
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Battle feature coming soon!')),
            );
          },
        );
      case TerritoryType.unclaimed:
        return _chip('🏳️ Unclaimed — run here to claim!', Colors.grey);
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color get _typeColor {
    switch (territory.type) {
      case TerritoryType.own:
        return AppColors.primaryTeal;
      case TerritoryType.friend:
        return AppColors.friendTerritory;
      case TerritoryType.enemy:
        return AppColors.enemyTerritory;
      case TerritoryType.unclaimed:
        return Colors.grey;
    }
  }
}
