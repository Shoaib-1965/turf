import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

/// Territory capture breakdown card with teal left accent bar.
class TerritoryBreakdownCard extends StatelessWidget {
  final double totalCaptured;
  final double newTerritory;
  final double reclaimedTerritory;
  final int competitionPoints;

  const TerritoryBreakdownCard({
    super.key,
    required this.totalCaptured,
    required this.newTerritory,
    required this.reclaimedTerritory,
    required this.competitionPoints,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.80),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Teal accent bar ─────────────────────────
              Container(
                width: 4,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
              ),

              // ── Content ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TERRITORY CAPTURED',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Total
                      Text(
                        '${totalCaptured.toStringAsFixed(2)} km²',
                        style: GoogleFonts.robotoMono(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Breakdown rows
                      _breakdownRow(
                        'New territory',
                        '${newTerritory.toStringAsFixed(2)} km²',
                        AppColors.primaryTeal,
                      ),
                      const SizedBox(height: 8),
                      _breakdownRow(
                        'Reclaimed',
                        '${reclaimedTerritory.toStringAsFixed(2)} km²',
                        AppColors.accentTeal,
                      ),
                      const SizedBox(height: 8),
                      _breakdownRow(
                        'Competition points earned',
                        '$competitionPoints',
                        AppColors.goldAccent,
                        icon: Icons.emoji_events_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color color,
      {IconData? icon}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
