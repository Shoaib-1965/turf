import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

/// Bottom glass HUD card showing live run stats.
class RunStatsHud extends StatelessWidget {
  final String pace;
  final String distance;
  final String duration;
  final String territory;
  final String calories;

  const RunStatsHud({
    super.key,
    required this.pace,
    required this.distance,
    required this.duration,
    required this.territory,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 1: Primary stats (large) ────────────
              Row(
                children: [
                  Expanded(
                    child: _primaryStat(pace, 'PACE', '/km'),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: Colors.grey[200],
                  ),
                  Expanded(
                    child: _primaryStat(distance, 'DISTANCE', 'km'),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Colors.grey[200]),
              ),

              // ── Row 2: Secondary stats ─────────────────
              Row(
                children: [
                  Expanded(child: _secondaryStat(duration, 'DURATION')),
                  _vertDivider(),
                  Expanded(child: _secondaryStat(territory, 'TERRITORY')),
                  _vertDivider(),
                  Expanded(child: _secondaryStat(calories, 'CALORIES')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryStat(String value, String label, String unit) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.robotoMono(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _secondaryStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 32, color: Colors.grey[200]);
  }
}
